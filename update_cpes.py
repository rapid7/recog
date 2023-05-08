#!/usr/bin/env python

import logging
import re
import sys

import yaml
from lxml import etree

BASE_LOG_FORMAT = '%(levelname)s: %(message)s'

# CPE w/o 2.3 component: cpe:/a:nginx:nginx:0.1.0"
REGEX_CPE = re.compile('^cpe:/([aho]):([^:]+):([^:]+)')
# CPE w/  2.3 component: cpe:2.3:a:f5:nginx:0.1.0:*:*:*:*:*:*:*
REGEX_CPE_23 = re.compile('^cpe:2.3:([aho]):([^:]+):([^:]+)')

XML_PATH_DEPRECATED_BY = "./{http://scap.nist.gov/schema/cpe-extension/2.3}cpe23-item/{http://scap.nist.gov/schema/cpe-extension/2.3}deprecation/{http://scap.nist.gov/schema/cpe-extension/2.3}deprecated-by"

# Percent-encoded character decode dict
PERCENT_DECODE = {
    '%21': '!',
    '%22': '\"',
    '%23': '#',
    '%24': '$',
    '%25': '%',
    '%26': '&',
    '%27': '\'',
    '%28': '(',
    '%29': ')',
    '%2a': '*',
    '%2b': '+',
    '%2c': ',',
    '%2f': '/',
    '%3a': ':',
    '%3b': ';',
    '%3c': '<',
    '%3d': '=',
    '%3e': '>',
    '%3f': '?',
    '%40': '@',
    '%5b': '[',
    '%5c': '\\',
    '%5d': ']',
    '%5e': '^',
    '%60': '`',
    '%7b': '{',
    '%7c': '|',
    '%7d': '}',
    '%7e': '~'
}

# Percent-encode character dict created from the decode dict
PERCENT_ENCODE = dict([(v, k) for k, v in PERCENT_DECODE.items()])

# Percent decode and encode regex patterns created by joining translation dictionary keys with regex OR
PERCENT_DECODE_PATTERN = re.compile('|'.join(PERCENT_DECODE))
PERCENT_ENCODE_PATTERN = re.compile('|'.join(list(map(re.escape, PERCENT_DECODE.values()))))

# Regex pattern used to check for interpolation markers
INTERPOLATION_PATTERN = re.compile(r'.*\{[^\s]+\}.*')


def repl_dict(pattern, d, s):
    """Performs regex replacement in string s by matching the pattern created from the translation
    dictionary d
    Args:
        pattern (re.Pattern): regex to match the key values in the translation dictionary d
        d (dict): translation dictionary where the key is the value to match and the value the replacement
        s (str): input string to process for replacements

    Returns:
        str, input string processed for replacements
    """
    # use lambda as repl function to lookup replacement value based on match
    return pattern.sub(lambda m: d[m.group()], s)


def parse_r7_remapping(file):
    with open(file) as remap_file:
        return yaml.safe_load(remap_file)["mappings"]


def update_vp_map(target_map, cpe_type, vendor, product):
    """Add an entry to the dict tracking valid combinations
    """

    if cpe_type not in target_map:
        target_map[cpe_type] = {}

    if vendor not in target_map[cpe_type]:
        target_map[cpe_type][vendor] = set()

    target_map[cpe_type][vendor].add(product)


def update_deprecated_map(target_map, dep_string, entry):
    """Add an entry to the dict tracking deprecations

    target_map example:

    {
      "a:100plus:101eip":
        {
          "deprecated_date": "2021-06-10T15:28:05.490Z",
          "deprecated_by": "a:hundredplus:101eip"
        }
    }

    Args:
        target_map (dict): dict containing deprecations
        dep_string (str): key to add in the format of 'type:vendor:product'
        entry (lxml.etree._Element): XML element to pull additional data from

    Returns:
        None, target_map modified in place
    """

    deprecated_date = entry.get("deprecation_date", "")

    # Find the CPE that deprecated this entry
    raw_dep_by = entry.find(XML_PATH_DEPRECATED_BY).get('name')

    # Extract the type, vendor, product
    dep_by_match = REGEX_CPE_23.match(raw_dep_by)
    if not dep_by_match:
        logging.error("CPE %s is deprecated but we can't build the deprecation mapping entry for some reason.", dep_string)
        return

    dep_type, dep_vendor, dep_product = dep_by_match.group(1, 2, 3)
    deprecated_by = "{}:{}:{}".format(dep_type, dep_vendor, dep_product)

    if dep_string not in target_map:
        target_map[dep_string] = {}

    if not target_map[dep_string].get('deprecated_date'):
        target_map[dep_string]['deprecated_date'] = deprecated_date

    if not target_map[dep_string].get('deprecated_by'):
        target_map[dep_string]['deprecated_by'] = deprecated_by


def parse_cpe_vp_map(file):
    deprecated_map = {}
    vp_map = {} # cpe_type -> vendor -> products

    parser = etree.XMLParser(remove_comments=False)
    doc = etree.parse(file, parser)
    namespaces = {
        'ns':     'http://cpe.mitre.org/dictionary/2.0',
        'meta':   'http://scap.nist.gov/schema/cpe-dictionary-metadata/0.2'
    }
    for entry in doc.xpath("//ns:cpe-list/ns:cpe-item", namespaces=namespaces):
        cpe_name = entry.get("name")
        if not cpe_name:
            continue

        cpe_match = REGEX_CPE.match(cpe_name)
        if cpe_match:
            cpe_type, vendor, product = cpe_match.group(1, 2, 3)
            # If the entry is deprecated then don't add it to our list of valid
            # CPEs, but instead add it to a list for reference later.
            if entry.get("deprecated"):
                # This will be the key under which we store the deprecation data
                deprecated_string = "{}:{}:{}".format(cpe_type, vendor, product)

                update_deprecated_map(deprecated_map, deprecated_string, entry)
                continue

            update_vp_map(vp_map, cpe_type, vendor, product)

        else:
            logging.error("Unexpected CPE %s", cpe_name)

    return vp_map, deprecated_map


def lookup_cpe(vendor, product, cpe_type, cpe_table, remap, deprecated_map):
    """Identify the correct vendor and product values for a CPE

    This function attempts to determine the correct CPE using vendor and product
    values supplied by the caller as well as a remapping dictionary for mapping
    these values to more correct values used by NIST.

    For example, the remapping might tell us that a value of 'alpine' for the
    vendor string should be 'alpinelinux' instead, or for product 'solaris'
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
        deprecated_cves (set): set of all deprecated CPEs in the format
            'type:vendor:product'
    Returns:
        success, vendor, product
    """

    if (
        vendor in cpe_table[cpe_type]
        and product in cpe_table[cpe_type][vendor]
    ):
        # Hot path, success with original values
        logging.debug(f"lookup_cpe: Hot path, success with original values; vendor = {vendor}, product = {product}")
        return True, vendor, product

    # Everything else depends on a remap of some sort.
    # get the remappings for this one vendor string.
    vendor_remap = None

    remap_type = remap.get(cpe_type, None)
    if remap_type:
        vendor_remap = remap_type.get(vendor, None)

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
            logging.debug(f"lookup_cpe: Found original vendor, remap product; vendor = {vendor}, possible_product = {possible_product}")
            return True, vendor, possible_product

        # Start working the process to find a match with a remapped vendor name
        if vendor_remap.get('vendor', None):
            new_vendor = vendor_remap['vendor']

            if new_vendor in cpe_table[cpe_type]:

                if product in cpe_table[cpe_type][new_vendor]:
                    # Found remap vendor, original product
                    logging.debug(f"lookup_cpe: Found remap vendor, original product; new_vendor = {new_vendor}, product = {product}")
                    return True, new_vendor, product

                if possible_product and possible_product in cpe_table[cpe_type][new_vendor]:
                    # Found remap vendor, remap product
                    logging.debug(f"lookup_cpe: Found remap vendor, remap product; new_vendor = {new_vendor}, possible_product = {possible_product}")
                    return True, new_vendor, possible_product

    deprecated_string = "{}:{}:{}".format(cpe_type, vendor, product)
    if deprecated_map.get(deprecated_string, False):
        dep_by = deprecated_map[deprecated_string].get("deprecated_by", "")
        dep_date = deprecated_map[deprecated_string].get("deprecated_date", "")
        logging.error("Product %s from vendor %s invalid for CPE %s and no mapping.  This combination is DEPRECATED by %s at %s",
                    product, vendor, cpe_type, dep_by, dep_date)
    else:
        logging.error("Product %s from vendor %s invalid for CPE %s and no mapping.",
                    product, vendor, cpe_type)

    return False, None, None


def update_cpes(xml_file, cpe_vp_map, r7_vp_map, deprecated_cves):
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

                if 'unknown' in [vendor, product]:
                    continue

                if INTERPOLATION_PATTERN.match(vendor) or INTERPOLATION_PATTERN.match(product):
                    continue

                vendor = vendor.lower().replace(' ', '_').replace(',', '')
                product = product.lower().replace(' ', '_').replace(',', '')

                tmp_product = product
                product = repl_dict(PERCENT_ENCODE_PATTERN, PERCENT_ENCODE, product)
                if tmp_product != product:
                    logging.debug(f"update_cpes: percent-encoded product {tmp_product} => {product}")

                success, vendor, product = lookup_cpe(vendor, product, cpe_type, cpe_vp_map, r7_vp_map, deprecated_cves)
                if not success:
                    continue

                # Sanity check the value to ensure that no invalid values will
                # slip in due to logic or mapping bugs.
                # If it's not in the official NIST list then log it and kick it out
                if product not in cpe_vp_map[cpe_type][vendor]:
                    logging.error("Invalid CPE type %s created for vendor %s and product %s. This may be due to an invalid mapping.", cpe_type, vendor, product)
                    continue

                # Create CPE string in URI Binding format value where variables are percent-encoded.
                # Note, this is only a partially complete encoding.
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


def main():
    if len(sys.argv) != 4:
        logging.critical("Expecting exactly 3 arguments; recog XML file, CPE 2.3 XML dictionary, JSON remapping, got %s", (len(sys.argv) - 1))
        sys.exit(1)

    cpe_vp_map, deprecated_map = parse_cpe_vp_map(sys.argv[2])
    if not cpe_vp_map:
        logging.critical("No CPE vendor => product mappings read from CPE 2.3 XML dictionary %s", sys.argv[2])
        sys.exit(1)

    r7_vp_map = parse_r7_remapping(sys.argv[3])
    if not r7_vp_map:
        logging.warning("No Rapid7 vendor/product => CPE mapping read from %s", sys.argv[3])

    # update format string for the logging handler to include the recog XML filename
    logging.basicConfig(force=True, format=f"{sys.argv[1]}: {BASE_LOG_FORMAT}")

    update_cpes(sys.argv[1], cpe_vp_map, r7_vp_map, deprecated_map)


if __name__ == '__main__':
    logging.basicConfig(format=BASE_LOG_FORMAT)
    try:
        sys.exit(main())
    except KeyboardInterrupt:
        pass
