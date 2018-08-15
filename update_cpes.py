#!/usr/bin/env python

import re
import sys

from lxml import etree, objectify

if len(sys.argv) != 2:
    raise ValueError("Expecting exactly 1 argument for XML file to add CPEs to, got {}".format(len(sys.argv) - 1))

xml_file = sys.argv[1]

parser = etree.XMLParser(remove_comments=False)
doc = etree.parse(xml_file, parser)

for fingerprint in doc.xpath('//fingerprint'):

    # collect all the params, grouping by os and service params that could be used to compute a CPE
    params = {}
    for param in fingerprint.xpath('./param'):
        name = param.attrib['name']
        # remove any existing CPE params
        if name.endswith('.cpe'):
            param.getparent().remove(param)

        match = re.search('^(?P<fp_type>os|service)\.', name)
        if match:
            fp_type = match.group('fp_type')
            if not fp_type in params:
                params[fp_type] = {}
            if name in params[fp_type]:
                raise ValueError('Duplicated fingerprint named {} in {}'.format(name, fingerprint.attrib['pattern']))
            params[fp_type][name] = param


    # for each of the applicable os/service param groups, build a CPE
    for fp_type in params:
        # start building the base CPE string
        cpe_value = "cpe:"
        if fp_type == 'os':
            cpe_value += "/o:"
        elif fp_type == 'service':
            cpe_value += "/a:"
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
            cpe_value += "{}:{}".format(vendor.lower(), product.lower()).replace(' ', '_')
            if version:
                cpe_value += ":{}".format(version)

            cpe_param = etree.Element('param')
            cpe_param.attrib['pos'] = '0'
            cpe_param.attrib['name'] = '{}.cpe'.format(fp_type)
            cpe_param.attrib['value'] = cpe_value

            parent = param.getparent()
            for param_name in params[fp_type]:
                parent.insert(parent.index(param)+1, cpe_param)

root = doc.getroot()

with open(xml_file, 'w') as fh:
    fh.write(etree.tostring(root, pretty_print=True, xml_declaration=True, encoding=doc.docinfo.encoding))
