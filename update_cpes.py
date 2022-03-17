#!/usr/bin/env python

import itertools
import logging
import re
import sys

import yaml
from lxml import etree

BASE_LOG_FORMAT = '%(levelname)s: %(message)s'

XML_PATH_DEPRECATED_BY = "./{http://scap.nist.gov/schema/cpe-extension/2.3}cpe23-item/{http://scap.nist.gov/schema/cpe-extension/2.3}deprecation/{http://scap.nist.gov/schema/cpe-extension/2.3}deprecated-by"

class CPELookupTree:
    def __init__(self):
        self.root = {}

    def insert(self, *fields):
        """Insert the given fields into the tree.

        Arg:
            *fields: fields to insert

        Returns:
            None
        """
        node = self.root
        for field in fields:
            if field not in node:
                node[field] = {}
            node = node[field]

    def get_subfields(self, *fields):
        """Get the list of fields one level below the provided fields.

        Arg:
            *fields (str tuple): fields to traverse

        Returns:
            List of keys one level below the *fields
        """
        node = self.root
        for field in fields:
            if field not in node:
                return []
            node = node[field]
        return list(node.keys())

    def _contains(self, node, depth, *fields):
        # If we don't need to look deeper,
        # we've found a match
        if len(fields) == 0:
            return True

        # If the current field exists in the
        # node, recurse one level downwards
        field = fields[0]
        fields = fields[1:]

        # Do not recurse solely into wildcard fields,
        # or we'll miss a ton of valid CPEs
        if field in node and not is_wildcard(field):
            return self._contains(node[field], depth+1, *fields)

        # If the current field is a wildcard
        # or unknown, recurse into all options
        #
        # HACK: The real intention of the depth field is to grab the field
        #       that is meant to be a version. We do this to allow versions
        #       that don't strictly match a CPE so long as their value is in
        #       some dotted decimal notation.
        #
        #       This is somewhat common; for example, ubuntu linux doesn't have
        #       specific CPEs for many versions (e.g. 6.04). We cannot allow
        #       _anything_ to be a version to prevent parsed "versions" such as
        #       "6.5_sp3_cpr" from ending up in a CPE.
        if is_wildcard(field) or (depth == 3 and is_versionlike(field)):
            # If all the rest of the fields are
            # wildcards too, this is a match.
            if False not in [is_wildcard(x) for x in fields]:
                return True

            for option in node:
                if self._contains(node[option], depth+1, *fields):
                    return True
            return False

        # Note that anything should match a wildcard field,
        # but it complicates the logic by a lot.
        # The caller of contains() would need to know which
        # field was substituted to build a valid CPE
        #
        # For now, just ignore this case.

        # If there were no options, it isn't here
        return False

    def contains(self, *fields):
        """Check if the given fields are in the tree.

        Checks all subfields at a level if the corresponding element
        in *fields is a CPE wildcard, or has a R7 fingerprint substitution.

        This method is also very permission with respect to versions;
        versions that are dotted decimal will be treated as wildcards
        since many CPEs aren't formally specified.

        See inner implementation: _contains(self, *fields)

        Arg:
            *fields (str tuple): fields of the CPE to check

        Returns:
            Boolean
        """
        return self._contains(self.root, 0, *fields)

substitution_pattern = re.compile("{((os)|(hw)|(service))\..*}")
versionlike_pattern = re.compile("(\d+\.)*\d+$")

def has_substitution(s):
    return bool(substitution_pattern.match(s))

def is_wildcard(s):
    return s == "-" or s == "*" or has_substitution(s)

def is_versionlike(s):
    return bool(versionlike_pattern.match(s))

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

    product = product.replace('%2f', '/')
    target_map[cpe_type][vendor].add(product)

def parse_cpe_vp_map(file):
    deprecated_map = CPELookupTree()
    vp_map = CPELookupTree()
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

        trimmed_cpe = ""
        if cpe_name.startswith("cpe:/"):
            trimmed_cpe = cpe_name[5:]

        if cpe_name.startswith("cpe:2.3:"):
            trimmed_cpe = cpe_name[8:]

        if len(trimmed_cpe) > 0:
            cpe_split = [x.replace("%2f", "/") for x in cpe_name[5:].split(":")]
            # Extract sw_ed, t_sw, t_hw, and `other` packed fields, if present
            if cpe_split[-1].count("~") == 4:
                packed = cpe_split.pop()
                cpe_split.extend(packed.split("~"))

            # If the entry is deprecated then don't add it to our list of valid
            # CPEs, but instead add the part:vendor:product to the deprecated CPE tree
            #
            # Also store the deprecation date and raw entry there.
            if entry.get("deprecated"):
                dep_date = entry.get("deprecation_date", "")
                dep_entry = entry.find(XML_PATH_DEPRECATED_BY).get("name")
                deprecated_map.insert(*cpe_split[:3], (dep_entry, dep_date))
            else:
                vp_map.insert(*cpe_split)
        else:
            logging.error("Unexpected CPE %s", cpe_name)

    return vp_map, deprecated_map

def lookup_cpe(fields, cpe_table, remap, dep_table):
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
        fields (List[str]): list of CPE fields from left to right, including cpe type.
                            It contains 7 elements.
        cpe_table (CPELookupTree): tree containing the official NIST CPE data
        dep_table (CPELookupTree): tree containing deprecated CPE information
        remap (dict): dict containing the remapping values
        deprecated_cves (set): set of all deprecated CPEs in the format
            'type:vendor:product'
    Returns:
        success, correct_fields
    """
#    deprecated_string = "{}:{}:{}".format(cpe_type, vendor, product)
#    if deprecated_map.get(deprecated_string, False):
#        dep_by = deprecated_map[deprecated_string].get("deprecated_by", "")
#        dep_date = deprecated_map[deprecated_string].get("deprecated_date", "")
#        logging.error("Product %s from vendor %s invalid for CPE %s and no mapping.  This combination is DEPRECATED by %s at %s",
#                    product, vendor, cpe_type, dep_by, dep_date)
#    else:
#        logging.error("Product %s from vendor %s invalid for CPE %s and no mapping.",
#                    product, vendor, cpe_type)
    # Hot path, success with all original values
    if cpe_table.contains(*fields):
        return True, fields


    if len(fields) != 6:
        logging.error(f"fields in lookup_cpe doesn't have 6 fields? {fields=}")
        return False, None

    # Build a list of lists.
    # It will have 7 elements;
    # each contains the options for a particular CPE field.
    options = []

    # CPE type
    cpe_type = fields[0]
    options.append(set([cpe_type]))

    # Fetch vendor specific mappings
    vendor_remap = remap.get(cpe_type, {}).get(fields[1], {})

    # Hot path out if there are no remappings for this vendor
    if not vendor_remap:
        return False, None

    # The CPE remap file looks like this:
    #
    # a:
    #   someVendor:
    #     vendor: remappedVendor
    #     products:
    #       someProduct:
    #         product: remappedProduct
    #         versions:
    #           someVersion:
    #             version: remappedVersion
    #             updates:
    #               someUpdate:
    #                 update: remappedUpdate
    #                 editions:
    #                   someEdition:
    #                     edition: remappedEdition
    #                     languages:
    #                       someLanguage:
    #                         language: remappedLanguage

    # Vendor
    vendor_options = [fields[1]]
    alt_vendor = vendor_remap.get("vendor")
    if alt_vendor:
        vendor_options.append(alt_vendor)
    options.append(vendor_options)

    # Fetch product specific mappings
    product_map = vendor_remap.get("products", {}).get(fields[2], {})

    # Product
    product_options = [fields[2]]
    alt_product = product_map.get("product", None)
    if alt_product:
        product_options.append(alt_product)
    options.append(product_options)

    # Fetch version specific mappings
    version_map = product_map.get("versions", {}).get(fields[3], {})

    # Version
    version_options = [fields[3]]
    alt_version = version_map.get("version", None)
    if alt_version:
        version_options.append(alt_version)
    options.append(version_options)

    # Fetch update specific mappings
    update_map = version_map.get("updates", {}).get(fields[4], {})

    # Update
    update_options = [fields[4]]
    alt_update = update_map.get("update", None)
    if alt_update:
        update_options.append(alt_update)
    options.append(update_options)

    # Fetch edition specific mappings
    edition_map = update_map.get("editions", {}).get(fields[5], {})

    # Edition
    edition_options = [fields[5]]
    alt_edition = edition_map.get("edition", None)
    if alt_edition:
        edition_options.append(alt_edition)
    options.append(edition_options)

    # Verify at least one level has an alternate option
    if max([len(x) for x in options]) == 1:
        return False, None

    # For every combination of options, preferring the
    # originals, check if it is present in the CPE table
    #
    # If found, return the fields!
    deps = set()
    for combination in itertools.product(*options):
        if cpe_table.contains(*combination):
            return True, combination

        # Build a set of deprecated CPEs as we go
        for dep in dep_table.get_subfields(*combination[:3]):
            deps.add(dep)

    # Pretty debug print
    cpe = ":".join(fields)

    err = f"CPE {cpe} had remappings, but none were valid."
    if len(deps) > 0:
        err += " It may be deprecated by one of:\n\t" + "\n\t".join([f"{x[0]} at {x[1]}" for x in deps])

    logging.error(err)
    return False, None

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
                'update': '*',
                'edition': '*',
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
            update = fp_data['update']
            edition = fp_data['edition']

            all_fields = [cpe_type, vendor, product, version, update, edition]

            # Skip any fingerprint that doesn't have a vendor and product
            if not vendor or not product:
                continue

            substitutions = [has_substitution(x) for x in all_fields]

            # HACK: Allow at most one substitution in generated CPEs
            #
            # The real intention here is to disallow generating CPEs
            # that require substituting in an optional capture group
            # to be valid. For example, this CPE,
            #
            #   cpe:/o:canonical:ubuntu_linux:{os.version}:*:{os.edition}
            #
            # Where we have a fingerprint that can match either a version alone
            # OR a version AND edition, can produce something like this
            #
            #   cpe:/o:canonical:ubuntu_linux:20.04:*:lts           ; okay
            #   cpe:/o:canonical:ubuntu_linux:20.04:*:{os.edition}  ; not okay
            #
            # This check helps prevent these situations, but is less than perfect.
            #
            # Also disallow substitutions in vendor/product.
            if True in substitutions[:3] or substitutions[3:].count(True) > 1:
               continue

            # Log a special error for failures due to CPE type
            if not cpe_vp_map.contains(cpe_type):
                logging.error("Didn't find CPE type '%s' for '%s' '%s'", cpe_type, vendor, product)
                continue

            # Do some transformations to help make fields look reasonable
            all_fields = [x.lower().replace(" ", "_").replace(",", "").replace("!", "%21") for x in all_fields]

            if 'unknown' in [vendor, product]:
                continue

            success, cpe_fields = lookup_cpe(all_fields, cpe_vp_map, r7_vp_map, deprecated_cves)

            if not success:
                continue

            # Sanity check the value to ensure that no invalid values will
            # slip in due to logic or mapping bugs.
            # If it's not in the official NIST list then log it and kick it out
            if not cpe_vp_map.contains(cpe_fields[0], cpe_fields[1], cpe_fields[2]):
                logging.error("Invalid CPE type %s created for fields %s. This may be due to an invalid mapping.", cpe_fields[0], cpe_fields[1], cpe_fields[2])
                continue

            # building the CPE string
            # Last minute escaping of '/' and `!`
            cpe_fields = [x.replace("/", "\/").replace("%21", "\!") for x in cpe_fields]

            # Colon separated fields, then the edition field
            cpe_value = "cpe:/" + ":".join(cpe_fields)

            # Otherwise, remove any trailing wildcard fields
            cpe_value = re.sub("(:\*)+$", "", cpe_value)

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
    if len(sys.argv) != 3:
        logging.critical("Expecting exactly 2 arguments; CPE 2.3 XML dictionary, YAML remapping, got %s", (len(sys.argv) - 1))
        sys.exit(1)

    cpe_vp_map, deprecated_map = parse_cpe_vp_map(sys.argv[1])
    if not cpe_vp_map:
        logging.critical("No CPE vendor => product mappings read from CPE 2.3 XML dictionary %s", sys.argv[1])
        sys.exit(1)

    r7_vp_map = parse_r7_remapping(sys.argv[2])
    if not r7_vp_map:
        logging.warning("No Rapid7 vendor/product => CPE mapping read from %s", sys.argv[2])

    # update format string for the logging handler to include the recog XML filename
    logging.basicConfig(force=True, format=f"{sys.argv[1]}: {BASE_LOG_FORMAT}")

    files = sys.stdin.readlines()

    for number, file in enumerate(files):
        file = file.strip()
        update_cpes(file, cpe_vp_map, r7_vp_map, deprecated_map)

if __name__ == '__main__':
    logging.basicConfig(format=BASE_LOG_FORMAT)
    try:
        sys.exit(main())
    except KeyboardInterrupt:
        pass
