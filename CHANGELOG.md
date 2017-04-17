Changes from 2.0.5 to 2.0.6
===========================

```
HD Moore (2):
      Force input to be binary, resolves warnings about //n
      Convert unicode to plain text in examples

Joakim Kennedy (1):
      DCA-1216: Windows 10 Fingerprint

Jon Hart (33):
      Revert "Convert unicode to plain text in examples"
      Revert "Force input to be binary, resolves warnings about //n"
      Use no Regexp flags by default
      Rename regexp_factory rspec so that it actually runs
      Correct regexen and examples for French and Portuguese (not Spanish)
      Correct spec to test for proper flags
      Add test to ensure that multiple flags are combined
      Remove now unnecessary (right?) jruby rspec pending
      Correct required ruby version
      Minor code cleanup
      Update Ubuntu 12.04 OpenSSH fingerprint
      Remove over-gready fingerprint for OpenSSH on Ubuntu
      Add Debian Squeeze OpenSSH banner; remove greedy
      Add a fingerprint for OpenSSH with just a version, no comment
      Temporarily disable OpenSSH catch-all
      Relax the OpenSSH with just a version regex
      Add older Ubuntu 7.10 OpenSSH fingerprint
      Update Ubuntu 8.04 OpenSSH regex
      Consolidate and improve Ubuntu 10.04 SSH fingerprints
      Improve Ubuntu 10.10 SSH fingerprints
      Add Ubuntu 15.04 SSH fingerprint; relax earlier
      Relax as many Ubuntu OpenSSH fingerprints as possible
      Handle a.b.c edge cases for Ubuntu 14.04
      Add Debian Wheezy OpenSSH fingerprint
      Remove disabled OpenSSH catch-all -- we need to see these fail
      Land #63
      Correct older OS X FTPD fingerprint
      Add tnftpd FTP fingerprint
      Add catch-all for generic FTP implementations
      Update pure-ftpd fingerprints to support multiline
      Update some OS X fingerprints to support multiline
      Revert 8ac30ae; add back catch-all with new certainty
      Revert "Remove disabled OpenSSH catch-all -- we need to see these fail"

Tod Beardsley (4):
      Land #70, add Win10 SMB fingerprints
      Land #68, SSH detection improvements
      Land #69, tnftpd and FTP generic signatures
      Bumping to v2.0.6
```
