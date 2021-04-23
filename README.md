# Recog: A Recognition Framework

[![Gem Version](https://badge.fury.io/rb/recog.svg)](http://badge.fury.io/rb/recog)
[![Build Status](https://travis-ci.org/rapid7/recog.svg?branch=master)](https://travis-ci.org/rapid7/recog)


Recog is a framework for identifying products, services, operating systems, and hardware by matching fingerprints against data returned from various network probes. Recog makes it simple to extract useful information from web server banners, snmp system description fields, and a whole lot more.

Recog is open source, please see the [LICENSE](https://raw.githubusercontent.com/rapid7/recog/master/LICENSE) file for more information.

## Table of Contents

1. [Installation](#installation)
1. [Maturity](#maturity)
1. [Fingerprints](#fingerprints)
1. [Contributing](#contributing)

## Installation

Recog consists of both XML fingerprint files and an assortment of code, mostly in Ruby, that makes it easy to develop, test, and use the contained fingerprints. In order to use the included ruby code, a recent version of Ruby (2.31+) is required, along with Rubygems and the `bundler` gem. Once these dependencies are in place, use the following commands to grab the latest source code and install any additional dependencies.

```shell
$ git clone git@github.com:rapid7/recog.git
$ cd recog
$ bundle install
```

[^back to top](#recog-a-recognition-framework)

## Maturity

Please note that while the XML fingerprints themselves are quite stable and well-tested, the Ruby codebase in Recog is still fairly new and subject to change quickly. Please contact us (research[at]rapid7.com) before leveraging the Recog code within any production projects.

[^back to top](#recog-a-recognition-framework)

## Fingerprints

The fingerprints within Recog are stored in XML files, each of which is designed to match a specific protocol response string or field. For example, the file [ssh_banners.xml](https://github.com/rapid7/recog/blob/master/xml/ssh_banners.xml) can determine the os, vendor, and sometimes hardware product by matching the initial SSH daemon banner string.

A fingerprint file consists of an XML document like the following:

```xml
<fingerprints matches="ssh.banner">
  <fingerprint pattern="^RomSShell_([\d\.]+)$">
    <description>Allegro RomSShell SSH</description>
    <example service.version="4.62">RomSShell_4.62</example>
    <param pos="0" name="service.vendor" value="Allegro"/>
    <param pos="0" name="service.product" value="RomSShell"/>
    <param pos="1" name="service.version"/>
  </fingerprint>
</fingerprints>
```

The first line should always consist of the XML version declaration. The first element should always be a `fingerprints` block with a `matches` attribute indicating what data this fingerprint file is supposed to match. The `matches` attribute is normally in the form of `protocol.field`.

Inside of the `fingerprints` element there should be one or more `fingerprint` elements. Every `fingerprint` must contain a `pattern` attribute, which contains the regular expression to be used to match against the data.  An optional `flags` attribute can be specified to control how the regular expression is to be interpreted.  See [the Recog documentation for `FLAG_MAP`](http://www.rubydoc.info/gems/recog/Recog/Fingerprint/RegexpFactory#FLAG_MAP-constant) for more information.

Inside of the fingerprint, a `description` element should contain a human-readable string describing this fingerprint.

At least one `example` element should be present, however multiple `example` elements are preferred.  These elements are used as part of the test coverage present in `rspec` which validates that the provided data matches the specified regular expression.  Additionally, if the fingerprint is using the `param` elements to extract field values from the data (described next), you can add these expected extractions as attributes for the `example` elements.  In the example above, this:

```xml
<example service.version="4.62">RomSShell_4.62</example>
```

tests that `RomSShell_4.62` matches the provided regular expression and that the value of `service.version` is 4.62.

The `param` elements contain a `pos` attribute, which indicates what capture field from the `pattern` should be extracted, or `0` for a static string. The `name` attribute is the key that will be reported in the case of a successful match and the `value` will either be a static string for `pos` values of `0` or missing and taken from the captured field.

The `example` string can be base64 encoded to permit the use of unprintable characters.  To signal this to Recog an `_encoding` attribute with the value of `base64` is added to the `example` element.  Based64 encoded text that is longer than 80 characters may be wrapped with newlines as shown below to aid in readability.

````xml
<example _encoding="base64">
  dGllczGEAAAAlQQWMS4yLjg0MC4xMTM1NTYuMS40LjgwMAQuZGF0YS5yZW1vdmVkLjCEAAAAK
  AQdZG9tYWluQ29udHJvbGxlckZ1bmN0aW9uYWxpdHkxhAAAAAMEATc=
</example>
````

Additionally, examples can be placed in a directory with the same base name as the XML file, in the same directory as the XML file:

```
xml/services.xml
xml/services/file1
xml/services/file2
...
```

They can then be loaded using the `_filename` attribute:

```xml
<example _filename="file1"/>
```

This is useful for long examples.

[^back to top](#recog-a-recognition-framework)

## Contributing

The users and maintainers of Recog would greatly appreciate any contributions
you can make to the project. For guidelines and instructions please see
[CONTRIBUTING.MD](CONTRIBUTING.md)

[^back to top](#recog-a-recognition-framework)
