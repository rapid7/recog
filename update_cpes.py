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
    params = {}
    # organize all the params, looking for os and service fingerprints to modify
    for param in fingerprint.xpath('./param'):
        name = param.attrib['name']
        match = re.search('^(?P<fp_type>os|service)\.', name)
        if match:
            fp_type = match.group('fp_type')
            if not fp_type in params:
                params[fp_type] = {}
            if name in params[fp_type]:
                raise ValueError('Duplicated fingerprint named {} in {}'.format(name, fingerprint.attrib['pattern']))
            params[fp_type][name] = param


    for fp_type in params:
        cpe_value = "cpe:"

        if fp_type == 'os':
            cpe_value += "/o:"
        elif fp_type == 'service':
            cpe_value += "/a:"
        else:
            raise ValueError('Unhandled param type {}'.format(fp_type))

        vendor = None
        vendor_param_name = "{}.vendor".format(fp_type)
        if vendor_param_name in params[fp_type]:
            vendor_e = params[fp_type][vendor_param_name]
            if vendor_e.attrib['pos'] == '0':
                vendor = vendor_e.attrib['value']
            else:
                vendor = "{{{}}}".format(vendor_e.attrib['name'])

        product = None
        product_param_name = "{}.product".format(fp_type)
        if product_param_name in params[fp_type]:
            product_e = params[fp_type][product_param_name]
            if product_e.attrib['pos'] == '0':
                product = product_e.attrib['value']
            else:
                product = "{{{}}}".format(product_e.attrib['name'])

        version = None
        version_param_name = "{}.version".format(fp_type)
        if version_param_name in params[fp_type]:
            version_e = params[fp_type][version_param_name]
            if version_e.attrib['pos'] == '0':
                version = version_e.attrib['value']
            else:
                version = "{{{}}}".format(version_e.attrib['name'])

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
    fh.write(etree.tostring(root, pretty_print=True))
