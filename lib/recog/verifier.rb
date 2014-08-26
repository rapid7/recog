module Recog
class Verifier
  attr_reader :fingerprints, :reporter

  def initialize(fingerprints, reporter)
    @fingerprints = fingerprints
    @reporter = reporter
  end

  def verify_tests
    reporter.report(fingerprints.count) do
      fingerprints.each do |fp|
        reporter.print_name fp

        if fp.tests.length == 0
          warning = "'#{fp.name}' has no test cases"
          reporter.warning "WARN: #{warning}"
        end

        fp.tests.each do |test|
          match = test.match(fp.regex)
          if match
            info = { }
            fp.params.each_pair do |k,v|
              pos, value = v
              if pos == 0
                info[k] = value
              else
                info[k] = match[ pos ]
                if match[ pos ].to_s.empty?
                  warning = "'#{fp.name}' failed to match #{test.inspect} key '#{k}' with #{fp.regex}'"
                  reporter.warning "WARN: #{warning}"
                end
              end
            end

            reporter.success(test)
          else
            failure = "'#{fp.name}' failed to match #{test.inspect} with #{fp.regex}'"
            reporter.failure("FAIL: #{failure}")
          end
        end
      end
    end
  end
end
end
