#!/usr/bin/env python

import logging
import re
import sys

import yaml
from lxml import etree

def parse_r7_remapping(file):
    with open(file) as remap_file:
        return yaml.safe_load(remap_file)["mappings"]

def parse_cpe_vp_map(file):
    vp_map = {} # cpe_type -> vendor -> products
    parser = etree.XMLParser(remove_comments=False)
    doc = etree.parse(file, parser)
    namespaces = {'ns': 'http://cpe.mitre.org/dictionary/2.0', 'meta': 'http://scap.nist.gov/schema/cpe-dictionary-metadata/0.2'}
    for cpe_name in doc.xpath("//ns:cpe-list/ns:cpe-item/@name", namespaces=namespaces):
        cpe_match = re.match('^cpe:/([aho]):([^:]+):([^:]+)', cpe_name)
        if cpe_match:
            cpe_type, vendor, product = cpe_match.group(1, 2, 3)
            if cpe_type not in vp_map:
                vp_map[cpe_type] = {}
            if vendor not in vp_map[cpe_type]:
                vp_map[cpe_type][vendor] = set()
            product = product.replace('%2f', '/')
            vp_map[cpe_type][vendor].add(product)
        else:
            logging.error("Unexpected CPE %s", cpe_name)

    return vp_map

def main():
    if len(sys.argv) != 4:
        logging.critical("Expecting exactly 3 arguments; recog XML file, CPE 2.3 XML dictionary, JSON remapping, got %s", (len(sys.argv) - 1))
        sys.exit(1)

    cpe_vp_map = parse_cpe_vp_map(sys.argv[2])
    if not cpe_vp_map:
        logging.critical("No CPE vendor => product mappings read from CPE 2.3 XML dictionary %s", sys.argv[2])
        sys.exit(1)

    r7_vp_map = parse_r7_remapping(sys.argv[3])
    if not r7_vp_map:
        logging.warning("No Rapid7 vendor/product => CPE mapping read from %s", sys.argv[3])

    update_cpes(sys.argv[1], cpe_vp_map, r7_vp_map)

def lookup_cpe(vendor, product, cpe_type, cpe_table, remap):
    """Identify the correct vendor and product values for a CPE

    This function attempts to determine the correct CPE using vendor and product
    values supplied by the caller as well as a remapping dictionary for mapping
    these values to more correct values used by NIST.

    For example, the remapping might tell us that a value of 'alpine' for the
    vendor string should be 'aplinelinux' instead, or for product 'solaris'
    should be 'sunos'.

    This function should only emit values seen in the official NIST CPE list
    which is provided to it in cpe_table.

    Lookup priority:
    1. Original vendor / product
    2. Original vendor / remap product
    3. Remap vendor / original product
    4. Remap vendor / remap product

    Args:
        vendor (str):  vendor name
        product (str): product name
        cpe_type (str): CPE type - o, a, h, etc.
        cpe_table (dict): dict containing the official NIST CPE data
        remap (dict): dict containing the remapping values
    Returns:
        success, vendor, product
    """

    if (
        vendor in cpe_table[cpe_type]
        and product in cpe_table[cpe_type][vendor]
    ):
        # Hot path, success with original values
        return True, vendor, product

    # Everything else depends on a remap of some sort.
    # get the remappings for this one vendor string.
    vendor_remap = remap.get(vendor, None)

    if vendor_remap:
        # If we have product remappings, work that angle next
        possible_product = None
        if (
            vendor_remap.get('products', None)
            and product in vendor_remap['products']
        ):
            possible_product = vendor_remap['products'][product]

        if (vendor in cpe_table[cpe_type]
            and possible_product
            and possible_product in cpe_table[cpe_type][vendor]):
            # Found original vendor, remap product
            return True, vendor, possible_product

        # Start working the process to find a match with a remapped vendor name
        if vendor_remap.get('vendor', None):
            new_vendor = vendor_remap['vendor']

            if new_vendor in cpe_table[cpe_type]:

                if product in cpe_table[cpe_type][new_vendor]:
                    # Found remap vendor, original product
                    return True, new_vendor, product

                if possible_product and possible_product in cpe_table[cpe_type][new_vendor]:
                    # Found remap vendor, remap product
                    return True, new_vendor, possible_product


    logging.error("Product %s from vendor %s invalid for CPE %s and no mapping",
                  product, vendor, cpe_type)
    return False, None, None


def update_cpes(xml_file, cpe_vp_map, r7_vp_map):
    parser = etree.XMLParser(remove_comments=False, remove_blank_text=True)
    doc = etree.parse(xml_file, parser)

    for fingerprint in doc.xpath('//fingerprint'):

        # collect all the params, grouping by os and service params that could be used to compute a CPE
        params = {}
        for param in fingerprint.xpath('./param'):
            name = param.attrib['name']
            # remove any existing CPE params
            if re.match(r'^.*\.cpe\d{0,2}$', name):
                param.getparent().remove(param)
                continue

            match = re.search(r'^(?P<fp_type>hw|os|service(?:\.component)?)\.', name)
            if match:
                fp_type = match.group('fp_type')
                if not fp_type in params:
                    params[fp_type] = {}
                if name in params[fp_type]:
                    raise ValueError('Duplicated fingerprint named {} in fingerprint {} in file {}'.format(name, fingerprint.attrib['pattern'], xml_file))
                params[fp_type][name] = param


        # for each of the applicable os/service param groups, build a CPE
        for fp_type in params:
            if fp_type == 'os':
                cpe_type = 'o'
            elif fp_type.startswith('service'):
                cpe_type = 'a'
            elif fp_type == 'hw':
                cpe_type = 'h'
            else:
                raise ValueError('Unhandled param type {}'.format(fp_type))

            # extract the vendor/product/version values from each os/service group,
            # using the static value ('Apache', for example) when pos is 0, and
            # otherwise use a value that contains interpolation markers such that
            # products/projects that use recog content can insert the value
            # extracted from the banner/other data via regex capturing groups
            fp_data = {
                'vendor': None,
                'product': None,
                'version': '-',
            }
            for fp_datum in fp_data:
                fp_datum_param_name = "{}.{}".format(fp_type, fp_datum)
                if fp_datum_param_name in params[fp_type]:
                    fp_datum_e = params[fp_type][fp_datum_param_name]
                    if fp_datum_e.attrib['pos'] == '0':
                        fp_data[fp_datum] = fp_datum_e.attrib['value']
                    else:
                        fp_data[fp_datum] = "{{{}}}".format(fp_datum_e.attrib['name'])

            vendor = fp_data['vendor']
            product = fp_data['product']
            version = fp_data['version']

            # build a reasonable looking CPE value from the vendor/product/version,
            # lowercasing, replacing whitespace with _, and more
            if vendor and product:
                if not cpe_type in cpe_vp_map:
                    logging.error("Didn't find CPE type '%s' for '%s' '%s'", cpe_type, vendor, product)
                    continue

                vendor = vendor.lower().replace(' ', '_').replace(',', '')
                product = product.lower().replace(' ', '_').replace(',', '')
                if 'unknown' in [vendor, product]:
                    continue

                if (vendor.startswith('{') and vendor.endswith('}')) or (product.startswith('{') and product.endswith('}')):
                    continue

                success, vendor, product = lookup_cpe(vendor, product, cpe_type, cpe_vp_map, r7_vp_map)
                if not success:
                    continue

                # Sanity check the value to ensure that no invalid values will
                # slip in due to logic or mapping bugs.
                # If it's not in the official NIST list then log it and kick it out
                if product not in cpe_vp_map[cpe_type][vendor]:
                    logging.error("Invalid CPE type %s created for vendor %s and product %s. This may be due to an invalid mapping.", cpe_type, vendor, product)
                    continue

                # building the CPE string
                # Last minute escaping of '/'
                product = product.replace('/', '\/')
                cpe_value = 'cpe:/{}:{}:{}'.format(cpe_type, vendor, product)

                if version:
                    cpe_value += ":{}".format(version)

                cpe_param = etree.Element('param')
                cpe_param.attrib['pos'] = '0'
                cpe_param.attrib['name'] = '{}.cpe23'.format(fp_type)
                cpe_param.attrib['value'] = cpe_value

                for param_name in params[fp_type]:
                    param = params[fp_type][param_name]
                    parent = param.getparent()
                    index = parent.index(param) + 1
                    parent.insert(index, cpe_param)

    root = doc.getroot()

    with open(xml_file, 'wb') as xml_out:
        xml_out.write(etree.tostring(root, pretty_print=True, xml_declaration=True, encoding=doc.docinfo.encoding))

if __name__ == '__main__':
    try: sys.exit(main())
    except KeyboardInterrupt: pass
