Feature: Verify
  @no-clobber
  Scenario: No tests
    When I run `recog_verify no_tests.xml`
    Then it should pass with exactly:
      """
      no_tests.xml: SUMMARY: Test completed with 0 successful, 0 warnings, and 0 failures
      """

  @no-clobber
  Scenario: Successful tests
    When I run `recog_verify successful_tests.xml`
    Then it should pass with exactly:
      """
      successful_tests.xml: SUMMARY: Test completed with 5 successful, 0 warnings, and 0 failures
      """

  @no-clobber
  Scenario: Tests with warnings, warnings disabled
    When I run `recog_verify --no-warnings tests_with_warnings.xml`
    Then it should pass with exactly:
      """
      tests_with_warnings.xml: SUMMARY: Test completed with 1 successful, 0 warnings, and 0 failures
      """
 
  # These tests vary due to line numbering issues in Nokogiri, so there are different versions
  # of the same test depending on the ruby runtime. Nokogiri uses libxml under CRuby, and a custom
  # java-based parser under JRuby. The Java-based parser only approximates line numbers, which are
  # typically off if XML prolog or comments are present.
  #
  # See https://github.com/sparklemotion/nokogiri/issues/2380
  @no-clobber
  @unsupported-on-platform-java
  Scenario: Tests with warnings, warnings enabled (CRuby)
    When I run `recog_verify tests_with_warnings.xml`
    Then it should fail with:
      """
      tests_with_warnings.xml:10: WARN: 'Pure-FTPd' has no test cases
      tests_with_warnings.xml: SUMMARY: Test completed with 1 successful, 1 warnings, and 0 failures
      """
    And the exit status should be 1
 
  # JRuby 9.2.20.1 and 9.3.3.0 differ in how they parse XML, where the latter is more close to libxml
  # and Nokogiri. We use a regex test to match results from both versions.
  @no-clobber
  @requires-ruby-platform-java
  Scenario: Tests with warnings, warnings enabled (JRuby)
    When I run `recog_verify tests_with_warnings.xml`
    Then it should fail with regex:
      """
      tests_with_warnings.xml:\d+: WARN: 'Pure-FTPd' has no test cases
      tests_with_warnings.xml: SUMMARY: Test completed with 1 successful, 1 warnings, and 0 failures
      """
    And the exit status should be 1

  @no-clobber
  @unsupported-on-platform-java
  Scenario: Tests with failures (CRuby)
    When I run `recog_verify tests_with_failures.xml`
    Then it should fail with:
      """
      tests_with_failures.xml:3: FAIL: 'foo test' failed to match "bar" with (?-mix:^foo$)'
      tests_with_failures.xml:8: FAIL: '' failed to match "This almost matches" with (?-mix:^This matches$)'
      tests_with_failures.xml:13: FAIL: 'bar test's os.name is a non-zero pos but specifies a value of 'Bar'
      tests_with_failures.xml:13: FAIL: 'bar test' failed to find expected capture group os.version '5.0'. Result was 1.0
      tests_with_failures.xml:20: FAIL: 'example with untested parameter' is missing an example that checks for parameter 'os.version' which is derived from a capture group
      tests_with_failures.xml: SUMMARY: Test completed with 1 successful, 0 warnings, and 5 failures
      """
    And the exit status should be 5
 
  # JRuby 9.2.20.1 and 9.3.3.0 differ in how they parse XML, where the latter is more close to libxml
  # and Nokogiri. We use a regex test to match results from both versions.
  @no-clobber
  @requires-ruby-platform-java
  Scenario: Tests with failures (JRuby)
    When I run `recog_verify tests_with_failures.xml`
    Then it should fail with regex:
      """
      tests_with_failures.xml:\d+: FAIL: 'foo test' failed to match "bar" with \(\?-mix:\^foo\$\)'
      tests_with_failures.xml:\d+: FAIL: '' failed to match "This almost matches" with \(\?-mix:\^This matches\$\)'
      tests_with_failures.xml:\d+: FAIL: 'bar test's os\.name is a non-zero pos but specifies a value of 'Bar'
      tests_with_failures.xml:\d+: FAIL: 'bar test' failed to find expected capture group os\.version '5\.0'. Result was 1\.0
      tests_with_failures.xml:\d+: FAIL: 'example with untested parameter' is missing an example that checks for parameter 'os\.version' which is derived from a capture group
      tests_with_failures.xml: SUMMARY: Test completed with 1 successful, 0 warnings, and 5 failures
      """
    And the exit status should be 5

  @no-clobber
  @unsupported-on-platform-java
  Scenario: recog_verify produces XML errors from the XSD with a malformed XML document (CRuby)
    When I run `recog_verify --schema-location ../../xml/fingerprints.xsd schema_failure.xml`
    Then it should fail with:
      """
      schema_failure.xml:3: FAIL: 3:0: ERROR: Element 'fingerprint', attribute 'name': The attribute 'name' is not allowed.
      schema_failure.xml:3: FAIL: 3:0: ERROR: Element 'fingerprint': The attribute 'pattern' is required but missing.
      schema_failure.xml:3: FAIL: 3:0: ERROR: Element 'fingerprint': Missing child element(s). Expected is ( description ).
      schema_failure.xml: SUMMARY: Test completed with 0 successful, 0 warnings, and 3 failures
      """
    And the exit status should be 3

  @no-clobber
  @requires-ruby-platform-java
  Scenario: recog_verify produces XML errors from the XSD with a malformed XML document (JRuby)
    When I run `recog_verify --schema_location ../../xml/fingerprints.xsd schema_failure.xml`
    Then it should fail with:
      """
      schema_failure.xml:-1: FAIL: -1:-1: ERROR: cvc-complex-type.3.2.2: Attribute 'name' is not allowed to appear in element 'fingerprint'.
      schema_failure.xml:-1: FAIL: -1:-1: ERROR: cvc-complex-type.4: Attribute 'pattern' must appear on element 'fingerprint'.
      schema_failure.xml:-1: FAIL: -1:-1: ERROR: cvc-complex-type.2.4.b: The content of element 'fingerprint' is not complete. One of '{description}' is expected.
      schema_failure.xml: SUMMARY: Test completed with 0 successful, 0 warnings, and 3 failures
      """
    And the exit status should be 3