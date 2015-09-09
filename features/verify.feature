Feature: Verify
  Scenario: No tests
    When I run `recog_verify no_tests.xml`
    Then it should pass with:
      """
      SUMMARY: Test completed with 0 successful, 0 warnings, and 0 failures
      """

  Scenario: Successful tests
    When I run `recog_verify successful_tests.xml`
    Then it should pass with:
      """
      SUMMARY: Test completed with 4 successful, 0 warnings, and 0 failures
      """

  Scenario: Tests with warnings
    When I run `recog_verify tests_with_warnings.xml`
    Then it should pass with:
      """
      WARN: 'Pure-FTPd' has no test cases
      SUMMARY: Test completed with 1 successful, 1 warnings, and 0 failures
      """

  Scenario: Tests with failures
    When I run `recog_verify tests_with_failures.xml`
    Then it should pass with:
      """
      FAIL: 'foo test' failed to match "bar" with (?-mix:^foo$)'
      FAIL: '' failed to match "This almost matches" with (?-mix:^This matches$)'
      FAIL: 'bar test' failed to find expected capture group os.version '5.0'
      SUMMARY: Test completed with 0 successful, 0 warnings, and 3 failures
      """

