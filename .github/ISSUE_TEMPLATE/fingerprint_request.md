---
name: Fingerprint request
about: Request new fingerprint coverage

---

**Request for new fingerprint(s) for a product**  
Briefly describe the product to be fingerprinted, including vendor and version information.  
<!-- Include links to relevant public documentation from the vendor or other sources, if available -->

**Provide details about the product**  
What protocol(s) can be used to retrieve identifiable information about the product?  
<!-- Examples: Telnet, SSH, SNMP, SMTP, HTTP(S), Vendor Proprietary Protocol -->

What information can be collected on each protocol?  
<!-- Example: HTTP Server banner: nginx/0.8.53 -->

What request, command, and/or payload can be used to retrieve information on each protocol?  
<!-- Use code fences like the below example to preserve formatting -->
```
HTTP HEAD /

HTTP GET /info.php
```

**Example banner(s) with specific version info**  
<!-- Paste raw text here, using code fences to preserve formatting if needed-->
