#!/usr/bin/env python


import logging
import re
import sys

from lxml import etree, objectify
from sets import Set

def parse_remapping(file):
    remap = {}
    with open(file, 'r') as p:
        for line in p:
            line = line.strip()
            map_match = re.match("^(?P<v_from>[^=]+)=(?P<v_to>[^=]+)$", line)
            if map_match:
                v_from = map_match.group('v_from')
                v_to = map_match.group('v_to')
                if v_from in remap:
                    raise ValueError("Duplicated '{}' from {}".format(v_from, file))
                else:
                    remap[v_from] = v_to
                    remap[v_to] = v_to
            else:
                remap[line] = line

    return remap

def parse_cpe_vp_map(file):
    map = {} # cpe_type -> vendor -> products
    parser = etree.XMLParser(remove_comments=False)
    doc = etree.parse(file, parser)
    final = 0
    #for final_cpe_name in doc.xpath("/cpe-list/cpe-item/*[local-name() = 'item-metadata' and @status = 'FINAL']/../@name"):
    namespaces = {'ns': 'http://cpe.mitre.org/dictionary/2.0', 'meta': 'http://scap.nist.gov/schema/cpe-dictionary-metadata/0.2'}
    for meta in doc.xpath("//ns:cpe-list/ns:cpe-item/meta:item-metadata[@status = 'FINAL']", namespaces=namespaces):
        final_cpe_name = meta.getparent().attrib['name']

        cpe_match = re.match('^cpe:/([aho]):([^:]+):([^:]+)', final_cpe_name)
        if cpe_match:
            cpe_type, vendor, product = cpe_match.group(1, 2, 3)
            cpe_type = cpe_type.encode('utf-8')
            vendor = vendor.encode('utf-8')
            product = product.encode('utf-8')
            if not cpe_type in map:
                map[cpe_type] = {}
            if not vendor in map[cpe_type]:
                map[cpe_type][vendor] = Set()
            map[cpe_type][vendor].add(product)
        else:
            logging.error("Unexpected CPE %s", final_cpe_name)

    return map


if len(sys.argv) != 5:
    raise ValueError("Expecting exactly 4 arguments; recog XML file, CPE XML dictionary, file of remapped vendors, file of remapped products, got {}".format(len(sys.argv) - 1))

xml_file = sys.argv[1]
parser = etree.XMLParser(remove_comments=False)
doc = etree.parse(xml_file, parser)
cpe_vp_map = parse_cpe_vp_map(sys.argv[2])
vendor_map = parse_remapping(sys.argv[3])
product_map = parse_remapping(sys.argv[4])

for fingerprint in doc.xpath('//fingerprint'):

    # collect all the params, grouping by os and service params that could be used to compute a CPE
    params = {}
    for param in fingerprint.xpath('./param'):
        name = param.attrib['name']
        # remove any existing CPE params
        if name.endswith('.cpe'):
            param.getparent().remove(param)
            continue

        match = re.search('^(?P<fp_type>hw|os|service)\.', name)
        if match:
            fp_type = match.group('fp_type')
            if not fp_type in params:
                params[fp_type] = {}
            if name in params[fp_type]:
                raise ValueError('Duplicated fingerprint named {} in {}'.format(name, fingerprint.attrib['pattern']))
            params[fp_type][name] = param


    # for each of the applicable os/service param groups, build a CPE
    for fp_type in params:
        if fp_type == 'os':
            cpe_type = 'o'
        elif fp_type == 'service':
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
            'version': None,
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
                logging.error("Didn't find CPE type %s", cpe_type)
                continue

            vendor = vendor.encode('utf-8').lower().replace(' ', '_').replace(',', '')
            product = product.encode('utf-8').lower().replace(' ', '_').replace(',', '')
            if 'unknown' in [vendor, product]:
                continue

            if vendor.startswith('{') and vendor.endswith('}'):
                continue
            else:
                if not vendor in cpe_vp_map[cpe_type]:
                    if vendor in vendor_map:
                        vendor = vendor_map[vendor]
                        if not vendor in cpe_vp_map[cpe_type]:
                            logging.error("Remapped vendor %s invalid for CPE %s", vendor, cpe_type)
                            continue
                    else:
                        logging.error("Vendor %s invalid for CPE %s and no remapping", vendor, cpe_type)
                        continue


            if product.startswith('{') and product.endswith('}'):
                continue
            else:
                if not product in cpe_vp_map[cpe_type][vendor]:
                    if product in product_map:
                        product = product_map[product]
                        if not product in cpe_vp_map[cpe_type][vendor]:
                            logging.error("Remapped product %s from %s invalid for CPE %s", product, vendor, cpe_type)
                            continue
                    else:
                        logging.error("Product %s from %s invalid for CPE %s and no mapping", product, vendor, cpe_type)
                        continue

            # building the CPE string
            cpe_value = 'cpe:/{}:{}:{}'.format(cpe_type, vendor, product)

            if version:
                cpe_value += ":{}".format(version)

            cpe_param = etree.Element('param')
            cpe_param.attrib['pos'] = '0'
            cpe_param.attrib['name'] = '{}.cpe'.format(fp_type)
            cpe_param.attrib['value'] = cpe_value

            parent = param.getparent()
            for param_name in params[fp_type]:
                param = params[fp_type][param_name]
                parent = param.getparent()
                index = parent.index(param) + 1
                parent.insert(index, cpe_param)

root = doc.getroot()

with open(xml_file, 'w') as fh:
    fh.write(etree.tostring(root, pretty_print=True, xml_declaration=True, encoding=doc.docinfo.encoding))
