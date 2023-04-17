# Recog: A Recognition Framework

[![CI Workflow](https://github.com/rapid7/recog/actions/workflows/ci.yml/badge.svg)](https://github.com/rapid7/recog/actions/workflows/ci.yml)
[![Verify Workflow](https://github.com/rapid7/recog/actions/workflows/verify.yml/badge.svg)](https://github.com/rapid7/recog/actions/workflows/verify.yml)

Recog is a framework for identifying products, services, operating systems, and hardware by matching fingerprints against data returned from various network probes. Recog makes it simple to extract useful information from web server banners, snmp system description fields, and a whole lot more.

Recog is open source, please see the [LICENSE](LICENSE) file for more information.

## Table of Contents

1. [Repository split](#repository-split)
    1. [Default branch rename](#default-branch-rename)
1. [Recog library language implementations](#recog-library-language-implementations)
    1. [Feature parity](#feature-parity)
1. [Installation](#installation)
1. [Maturity](#maturity)
1. [Fingerprints](#fingerprints)
1. [Contributing](#contributing)

## Repository split

On March 31, 2022, the Recog content - XML fingerprint files and utilities - were split from the Recog framework library implementation. The original [Recog](https://github.com/rapid7/recog) repository now contains the Recog content and the [Recog-Ruby](https://github.com/rapid7/recog-ruby) repository contains the Ruby language implementation. The Recog content is included in Recog-Ruby as a git submodule and is nested under the `recog` directory. All post-split Recog gem versions equal or greater than 3.0.0 will: 1. contain the XML fingerprint directory under the `recog` directory, and 2. only include the `recog_match` tool since the other tools are focused on fingerprint management.

[^back to top](#recog-a-recognition-framework)

### Default branch rename

Along with the repository split the default branch was renamed from `master` to `main`. Any clones created prior to these changes will have to be manually updated in your local environment. If you have a fork, navigate to your fork's settings and follow the instructions on [renaming a branch](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-branches-in-your-repository/renaming-a-branch) to change the default branch to `main`.

```
git branch -m master main
git fetch origin
git branch -u origin/main main
git remote set-head origin -a
```

Optionally, run the following command to remove tracking references to the old branch name.
```
# dry-run to confirm stale references that will be deleted before proceeding
git remote prune origin --dry-run
git remote prune origin
```

If you previously used the upstream tracking branch `upstream-master` run the following commands to remove the old branch and create a new upstream tracking branch.
```
git branch -d upstream-master
git checkout -b upstream-main --track upstream/main
```

Optionally, run the following command to remove the tracking references to the old upstream branch name.
```
# dry-run to confirm stale references that will be deleted before proceeding
git remote prune upstream --dry-run
git remote prune upstream
```

[^back to top](#recog-a-recognition-framework)

## Recog library language implementations

* Ruby: [rapid7/recog-ruby](https://github.com/rapid7/recog-ruby)
* Java: [rapid7/recog-java](https://github.com/rapid7/recog-java)
* Go: [runZeroInc/recog-go](https://github.com/runZeroInc/recog-go)

[^back to top](#recog-a-recognition-framework)

### Feature parity

| Feature :sparkles:                          | rapid7/recog-ruby  | rapid7/recog-java  | runZeroInc/recog-go |
|---------------------------------------------|:------------------:|:------------------:|:-------------------:|
| Fingerprint verification CLI tool           | :white_check_mark: | :white_check_mark: | :white_check_mark:  |
| Fingerprint match CLI tool                  | :white_check_mark: |                    | :white_check_mark:  |
| Supports base64 encoded examples            | :white_check_mark: | :white_check_mark: | :white_check_mark:  |
| Supports filesystem-based external examples | :white_check_mark: | :white_check_mark: | :white_check_mark:  |
| Fingerprint match CPE param interpolation   | :white_check_mark: | :white_check_mark: | :white_check_mark:  |

[^back to top](#recog-a-recognition-framework)

## Installation

Recog consists of both XML fingerprint files and an assortment of code, mostly in Ruby, that makes it easy to develop, test, and use the contained fingerprints. In order to use the included ruby code, a recent version of Ruby (2.31+) is required, along with Rubygems and the `bundler` gem. Once these dependencies are in place, use the following commands to grab the latest source code and install any additional dependencies.

```shell
$ git clone git@github.com:rapid7/recog.git
$ cd recog
$ bundle install
```

[^back to top](#recog-a-recognition-framework)

## Maturity

Please note that while the XML fingerprints themselves are quite stable and well-tested, the Ruby codebase is still fairly new and subject to change quickly. Please contact us (research[at]rapid7.com) before leveraging the Recog code within any production projects.

[^back to top](#recog-a-recognition-framework)

## Fingerprints

The fingerprints within Recog are stored in XML files, each of which is designed to match a specific protocol response string or field. For example, the file [ssh_banners.xml](xml/ssh_banners.xml) can determine the os, vendor, and sometimes hardware product by matching the initial SSH daemon banner string.

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

The `example` string can be base64 encoded to permit the use of unprintable characters.  To signal this to Recog an `_encoding` attribute with the value of `base64` is added to the `example` element.  Based64 encoded text that is longer than 80 characters may be wrapped with newlines as shown below to aid in readability.

```xml
<example _encoding="base64">
  dGllczGEAAAAlQQWMS4yLjg0MC4xMTM1NTYuMS40LjgwMAQuZGF0YS5yZW1vdmVkLjCEAAAAK
  AQdZG9tYWluQ29udHJvbGxlckZ1bmN0aW9uYWxpdHkxhAAAAAMEATc=
</example>
```

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

The `param` elements contain a `pos` attribute, which indicates what capture field
from the `pattern` should be extracted, or `0` for a static string. The `name` attribute
is the key that will be reported in the case of a successful match and the `value`
will either be a static string for `pos` values of `0` or missing and taken from the
captured field.

The `value` attribute supports interpolation of data from other fields. This is
often useful when capturing the value for `hw.product` via regex and re-using this
value in `os.product`.

Here is an example from`http_servers.xml` where `hw.product` is captured and reused.

```xml
  <fingerprint pattern="^Eltex (TAU-\d+[A-Z]*(?:\.IP)?)$">
    <description>Eltex TAU model VoIP gateway</description>
    <example hw.product="TAU-72">Eltex TAU-72</example>
    <example hw.product="TAU-1.IP">Eltex TAU-1.IP</example>
    <param pos="0" name="os.vendor" value="Eltex"/>
    <param pos="0" name="os.product" value="{hw.product} Firmware"/>
    <param pos="0" name="os.device" value="VoIP Gateway"/>
    <param pos="0" name="hw.vendor" value="Eltex"/>
    <param pos="1" name="hw.product"/>
    <param pos="0" name="hw.device" value="VoIP Gateway"/>
  </fingerprint>
```

There is special handling for temporary attributes that have a name starting with
`_tmp.`. These attributes can be used for interpolation but are not emitted in the
output. This is useful when a particular product name is inconsistent in various
banners, vendor marketing, or with NIST values when trying to generate CPEs. In
these cases the useful parts of the banner can be extracted and a new value
crafted without cluttering the data emitted by a match.

```xml
<fingerprint pattern="^foo baz switchThing-(\d{4})$">
  <description>NetCorp NX series switches</description>
  <example hw.product="NX8200">foo baz switchThing-8200</example>
  <param pos="0" name="hw.vendor" value="NetCorp"/>
  <param pos="0" name="hw.product" value="NX{_tmp.001}"/>
  <param pos="2" name="_tmp.001"/>
</fingerprint>
```

These temporary attributes are not tracked in the `identifiers/fields.txt`.

[^back to top](#recog-a-recognition-framework)

### Testing matches

The following examples make use of `bin/recog_match`, a simple Ruby command line tool that uses Recog's fingerprint data. Pre-processing is generally required before running Recog, i.e. extracting HTTP header values, etc. All fingerprint data can be found in `xml/*.xml`.

#### ftp_banners

Fingerprint FTP servers based on the server's banner response after connecting:

```
# Example plaintext input
echo -n '220 Microsoft FTP Service' | bin/recog_match xml/ftp_banners.xml -

# Example command using nmap
nmap -sV -script=banner -p 21 192.168.123.13 | grep --color=never '_banner' | cut -d: -f2- | bin/recog_match xml/ftp_banners.xml -

# Example output
MATCH: {"matched"=>"Microsoft FTP Server on Windows XP, 2003 or later without version", "service.vendor"=>"Microsoft", "service.product"=>"IIS", "service.family"=>"IIS", "service.cpe23"=>"cpe:/a:microsoft:iis:-", "os.vendor"=>"Microsoft", "os.family"=>"Windows", "os.product"=>"Windows", "os.cpe23"=>"cpe:/o:microsoft:windows:-", "host.name"=>"220", "service.protocol"=>"ftp", "fingerprint_db"=>"ftp.banner", "data"=>"220 Microsoft FTP Service"}
```

#### http_cookies

Using the HTTP `Set-Cookie` header value to fingerprint an HTTP server:

```
# Example plaintext input
echo 'laravel_session=eyJ...etc..etc...%3D; expires=Mon, 13-Mar-2023 16:48:58 GMT; Max-Age=7200; path=/; httponly; samesite=lax' | bin/recog_match xml/http_cookies.xml -

# Example cURL command
curl --silent -I http://localhost:9001 | grep --color=never -i '^Set-Cookie:' | cut -d: -f2- | bin/recog_match xml/http_cookies.xml -

# Example output
MATCH: {"matched"=>"Laravel PHP web application framework", "service.vendor"=>"Laravel", "service.product"=>"Laravel", "service.cpe23"=>"cpe:/a:laravel:laravel:-", "service.protocol"=>"http", "fingerprint_db"=>"http_header.cookie", "data"=>"laravel_session=eyJ...etc..etc...%3D; expires=Mon, 13-Mar-2023 16:48:58 GMT; Max-Age=7200; path=/; httponly; samesite=lax"}
```

#### http_servers

Using the HTTP `Server` header value to fingerprint an HTTP server:

```
# Example plaintext input
echo -n 'Apache/2.4.38 (Debian)' | bin/recog_match xml/http_servers.xml -

# Example cURL command
curl --silent -I http://localhost:9001 | grep --color=never -i '^Server:' | cut -d: -f2- | bin/recog_match xml/http_servers.xml -

# Example output
MATCH: {"matched"=>"Apache", "service.vendor"=>"Apache", "service.product"=>"HTTPD", "service.family"=>"Apache", "service.version"=>"2.4.38", "service.cpe23"=>"cpe:/a:apache:http_server:2.4.38", "apache.info"=>"(Debian)", "service.protocol"=>"http", "fingerprint_db"=>"http_header.server", "data"=>"Apache/2.4.38 (Debian)"}
```

#### favicons

Using the md5sum of a favicon to identify a running service:

```
# Example plaintext input
echo -n fe22dd2bb09daccf58256611ac491469 | bin/recog_match xml/favicons.xml -

# Example cURL command
curl --silent http://localhost:8000/favicon.ico | md5sum | awk '{ print $1 }' | bin/recog_match xml/favicons.xml -

# Example output
MATCH: {"matched"=>"Drupal CMS", "service.vendor"=>"Drupal", "service.product"=>"CMS", "service.certainty"=>"0.5", "service.cpe23"=>"cpe:/a:drupal:drupal:-", "service.protocol"=>"", "fingerprint_db"=>"favicon.md5", "data"=>"fe22dd2bb09daccf58256611ac491469"}
```

#### http_wwwauth

Using the HTTP `WWW-Authenticate` header value to fingerprint an HTTP server:

```
# Example plaintext input
echo -n 'Basic realm="monit"' | bin/recog_match xml/http_wwwauth.xml -

# Example cURL command
curl --silent -I http://localhost:9001 | grep --color=never -i '^WWW-Authenticate:' | cut -d: -f2- | bin/recog_match xml/http_wwwauth.xml -

# Example output
MATCH: {"matched"=>"Minot", "service.vendor"=>"Tildeslash", "service.product"=>"Monit", "service.cpe23"=>"cpe:/a:tildeslash:monit:-", "service.protocol"=>"http", "fingerprint_db"=>"http_header.wwwauth", "data"=>"Basic realm=\"monit\""}
```

#### tls_jarm

Fingerprint TLS servers based on the server's response to 10 TLS Client Hello packets. Fingerprint based on https://github.com/salesforce/jarm

```
# Example plaintext input
echo -n 07d14d16d21d21d07c42d43d000000f50d155305214cf247147c43c0f1a823 | bin/recog_match xml/jarm.xml -

# Example command using Salesforce's JARM against a running Metasploit listener
python3 $code/jarm/jarm.py -p 8443 192.168.123.1 | grep --color=never 'JARM: ' | awk -F: '{ print $2 }' | bin/recog_match xml/tls_jarm.xml -

# Example output
MATCH: {"matched"=>"Metasploit listener", "service.vendor"=>"Rapid7", "service.product"=>"Metasploit", "service.cpe23"=>"cpe:/a:rapid7:metasploit:-", "service.protocol"=>"tls", "fingerprint_db"=>"tls.jarm", "data"=>"07d14d16d21d21d07c42d43d000000f50d155305214cf247147c43c0f1a823"}
```

## Contributing

The users and maintainers of Recog would greatly appreciate any contributions
you can make to the project. For guidelines and instructions please see
[CONTRIBUTING.MD](CONTRIBUTING.md)

[^back to top](#recog-a-recognition-framework)
