#!/usr/bin/env python

import re
import sys

from lxml import etree, objectify

parser = etree.XMLParser(remove_comments=False)
doc = etree.parse(sys.argv[1], parser)

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
        for param_name in params[fp_type]:
            cpe = etree.fromstring('<param name="f.cpe"/>')
            param.append(cpe)

root = doc.getroot()

f = open(sys.argv[1], 'w')
f.write(etree.tostring(root, pretty_print=True))
f.close()
