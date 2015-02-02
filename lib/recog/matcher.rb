module Recog
class Matcher
  attr_reader :fingerprints, :reporter

  def initialize(fingerprints, reporter)
    @fingerprints = fingerprints
    @reporter = reporter
  end

  def match_banners(banners_file)
    reporter.report do

      fd = $stdin
      file_source = false

      if banners_file and banners_file != "-"
        fd = File.open(banners_file, "rb")
        file_source = true
      end

      fd.each_line do |line|
        reporter.increment_line_count

        line = line.to_s.unpack("C*").pack("C*").strip.gsub(/\\[rn]/, '')
        extractions = nil
        fingerprints.each do |fp|
          break if (extractions = fp.match(line))
        end

        if extractions
          extractions['data'] = line
          reporter.match "MATCH: #{extractions.inspect}"
        else
          reporter.failure "FAIL: #{line}"
        end

        if reporter.stop?
          break
        end
      end

      fd.close if file_source

    end
  end
end
end
