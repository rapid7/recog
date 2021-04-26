# Recog: Identifiers

This directory contains lists of standard identifiers for mapping Recog matches.
The goal is define a standard set of constants to represent known software,
hardware, vendors, and categories.

This is currently incomplete and will be updated as standardization work moves
forward.

Fingerprints should use these identifiers whenever possible; if a different name
or syntax for a given identifier is preferred, this should be implemented in the
application through a mapping function.

## Lists

### Fields

`fields.txt` defines the various fields (`os.vendor`, etc.) used to assert
information about a match.

### Vendors

`vendor.txt` defines known vendor names, covering services, operating systems,
and hardware.

### Operating Systems

`os_architecture.txt` defines known CPU types.

`os_product.txt` defines known operating system names.

`os_family.txt` defines known operating system families.

`os_device.txt` defines known types of devices by function or purpose.

### Hardware

`hw_product.txt` defines known hardware product names.

`hw_family.txt` defines known hardware product families.

`hw_device.txt` defines known types of devices by function or purpose (overlaps
with `os_device.txt`).

### Services

`service_product.txt` defines known service product names.

`service_family.txt` defines known service product families.

### Software

`software_product.txt` defines known software product names.

`software_family.txt` defines known software product families.

`software_class.txt` defines known types of software by function or purpose.

## Pending Work

* All existing fingerprints should be correlated against these lists to
  identify mismatches and updated accordingly.

* All net new identifiers from the existing fingerprints should be merged into
these lists.

* All fingerprint assertions should be enumerated, documented, and standardized
where possible (`host.mac`, etc).

* Hardware identifiers should be enumerated, consolidated, and standardized.
