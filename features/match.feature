Feature: Match
  Scenario: Finds matches
    When I run `recog_match matching_banners_fingerprints.xml sample_banner.txt`
    Then it should pass with:
      """
      MATCH: {"matched"=>"Pure-FTPd Config data can be zero or more of: [privsep] [TLS]", "pureftpd.config"=>"[privsep] [TLS] ", "service.family"=>"Pure-FTPd", "service.product"=>"Pure-FTPd", "data"=>"---------- Welcome to Pure-FTPd [privsep] [TLS] ----------"}
      MATCH: {"matched"=>"SunOS/Solaris", "os.vendor"=>"Sun", "os.family"=>"Solaris", "os.product"=>"Solaris", "os.device"=>"General", "host.name"=>"polaris", "os.version"=>"5.8", "data"=>"polaris FTP server (SunOS 5.8) ready."}
      """

  Scenario: Fails at finding matches
    When I run `recog_match failing_banners_fingerprints.xml sample_banner.txt`
    Then it should pass with:
      """
      FAIL: ---------- Welcome to Pure-FTPd [privsep] [TLS] ----------
      FAIL: polaris FTP server (SunOS 5.8) ready
      """
