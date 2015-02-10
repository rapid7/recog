Recog: A Recognition Framework
=====

Recog is a framework for identifying products, services, operating systems, and hardware by matching fingerprints against data returned from various network probes. Recog makes it simple to extract useful information from web server banners, snmp system description fields, and a whole lot more. Recog is open source, please see the [LICENSE](https://raw.githubusercontent.com/rapid7/recog/master/LICENSE) file for more information.

[![Build Status](https://travis-ci.org/rapid7/recog.png)](https://travis-ci.org/rapid7/recog)
==

## Installation

Recog consists of both XML fingerprint files and an assortment of code, mostly in Ruby, that makes it easy to develop, test, and use the contained fingerprints. In order to use the included ruby code, a recent version of Ruby (1.9.3+) is required, along with Rubygems and the `bundler` gem. Once these dependencies are in place, use the following commands to grab the latest source code and install any additional dependencies.

    $ git clone git@github.com:rapid7/recog.git
    $ cd recog
    $ bundle install

## Maturity

Please note that while the XML fingerprints themselves are quite stable and well-tested, the Ruby codebase in Recog is still fairly new and subject to change quickly. Please contact us (research[at]rapid7.com) before leveraging the Recog code within any production projects.

## Fingerprints

The fingerprints within Recog are stored in XML files, each of which is designed to match a specific protocol response string or field. For example, the file [ssh_banners.xml](https://github.com/rapid7/recog/blob/master/xml/ssh_banners.xml) can determine the os, vendor, and sometimes hardware product by matching the initial SSH daemon banner string.

A fingerprint file consists of an XML document like the following:

    01: <?xml version="1.0"?>
    02:
    03: <fingerprints matches="ssh.banner">
    04:
    05: <fingerprint pattern="^RomSShell_([\d\.]+)$">
    06:  <description>Allegro RomSShell SSH</description>
    07:  <example>RomSShell_4.62</example>
    08:  <param pos="0" name="service.vendor" value="Allegro"/>
    09:  <param pos="0" name="service.product" value="RomSShell"/>
    10:  <param pos="1" name="service.version"/>
    11: </fingerprint>
    12:
    13: </fingerprints>

The first line should always consist of the XML version declaration. The first element should always be a `fingerpints` block with a `matches` attribute indicating what this fingerprint file is supposed to match. The `matches` attribute is normally in the form of protocol.field.

Inside of the `fingerprints` element there should be one or more `fingerprint` elements. Every fingerprint should contain a `pattern` attribute, which contains the regular expression to be used against the match key.

Inside of the fingerprint, a `description` element should contain a human-readable string describing this fingerprint.

The `example` element should contain a successful match for the fingerprint's `pattern`. Multiple `example` elements are preferred, as these elements are used for the built-in regression testing suite.

The `param` elements contain a `pos` attribute, which indicates what capture field from the `pattern` should be extracted, or `0` for a static string. The `name` attribute is the key that will be reported in the case of a successful match and the `value` will either be a static string for `pos` values of `0` or missing and taken from the captured field.

Once a fingerprint has been added, the `example` entries can be tested by executing `bin/recog_verify` against the fingerprint file:

    $ bin/recog_verify xml/ssh_banners.xml

Matches can be tested on the command-line in a similar fashion:

    $ echo 'OpenSSH_6.6p1 Ubuntu-2ubuntu1' | bin/recog_match xml/ssh_banners.xml -
    MATCH: {"service.version"=>"6.6p1", "openssh.comment"=>"Ubuntu-2ubuntu1", "service.vendor"=>"OpenBSD", "service.family"=>"OpenSSH", "service.product"=>"OpenSSH", "data"=>"OpenSSH_6.6p1 Ubuntu-2ubuntu1"}







