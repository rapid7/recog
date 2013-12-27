Feature: Verify
  Scenario: No tests
    When I run `verify.rb no_tests.xml`
    Then it should pass with:
      """
      SUMMARY: Test completed with 0 successful, 0 warnings, and 0 failures
      """

  Scenario: Successful tests
    When I run `verify.rb successful_tests.xml`
    Then it should pass with:
      """
      SUMMARY: Test completed with 2 successful, 0 warnings, and 0 failures
      """

  Scenario: Tests with warnings
    When I run `verify.rb tests_with_warnings.xml`
    Then it should pass with:
      """
      WARN: 'Pure-FTPd' failed to match \"---------- Welcome to Pure-FTPd ----------\" key 'pureftpd.config'' with (?-mix:^-{10} Welcome to Pure-FTPd (.*)-{10}$)'
      SUMMARY: Test completed with 1 successful, 1 warnings, and 0 failures
      """

  Scenario: Tests with failures
    When I run `verify.rb tests_with_failures.xml`
    Then it should pass with:
      """
      FAIL: 'foo test' failed to match "bar" with (?-mix:^foo$)'
      FAIL: '' failed to match "This almost matches" with (?-mix:^This matches$)'
      SUMMARY: Test completed with 0 successful, 0 warnings, and 2 failures
      """
