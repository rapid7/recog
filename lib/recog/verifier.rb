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
          m = test.match(fp.regex)
          unless m
            failure = "'#{fp.name}' failed to match #{test.inspect} with #{fp.regex.to_s}'"
            reporter.failure("FAIL: #{failure}")
          else
            info = { }
            fp.params.each_pair do |k,v|
              if v[0] == 0
                info[k] = v[1]
              else
                info[k] = m[ v[0] ]
                if m[ v[0] ].to_s.empty?
                  warning = "'#{fp.name}' failed to match #{test.inspect} key '#{k}'' with #{fp.regex.to_s}'"
                  reporter.warning "WARN: #{warning}"
                end
              end
            end

            reporter.success(test)
          end
        end
      end
    end
  end
end
end
