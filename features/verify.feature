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
      successful_tests.xml: SUMMARY: Test completed with 4 successful, 0 warnings, and 0 failures
      """

  @no-clobber
  Scenario: Tests with warnings, warnings enabled
    When I run `recog_verify tests_with_warnings.xml`
    Then it should fail with:
      """
      tests_with_warnings.xml: WARN: 'Pure-FTPd' has no test cases
      tests_with_warnings.xml: WARN: 'Pure-FTPd' is missing an example that checks for parameter 'pureftpd.config' which is derived from a capture group
      tests_with_warnings.xml: SUMMARY: Test completed with 1 successful, 2 warnings, and 0 failures
      """
    And the exit status should be 2

  @no-clobber
  Scenario: Tests with warnings, warnings disabled
    When I run `recog_verify --no-warnings tests_with_warnings.xml`
    Then it should pass with exactly:
      """
      tests_with_warnings.xml: SUMMARY: Test completed with 1 successful, 0 warnings, and 0 failures
      """

  @no-clobber
  Scenario: Tests with failures
    When I run `recog_verify tests_with_failures.xml`
    Then it should fail with:
      """
      tests_with_failures.xml: FAIL: 'foo test' failed to match "bar" with (?-mix:^foo$)'
      tests_with_failures.xml: FAIL: '' failed to match "This almost matches" with (?-mix:^This matches$)'
      tests_with_failures.xml: FAIL: 'bar test's os.name is a non-zero pos but specifies a value of 'Bar'
      tests_with_failures.xml: FAIL: 'bar test' failed to find expected capture group os.version '5.0'. Result was 1.0
      tests_with_failures.xml: SUMMARY: Test completed with 0 successful, 0 warnings, and 4 failures
      """
    And the exit status should be 4
