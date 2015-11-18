module Recog
class Matcher
  attr_reader :fingerprints, :reporter, :multi_match

  # @param fingerprints Array of [Recog::Fingerprint]
  # @param reporter [Recog::MatchReporter]
  # @param multi_match [Boolean]
  def initialize(fingerprints, reporter, multi_match)
    @fingerprints = fingerprints
    @reporter = reporter
    @multi_match = multi_match
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
        foundExtractions = false
        fingerprints.each do |fp|
          extractions = fp.match(line)
          if extractions
            foundExtractions = true
            extractions['data'] = line
            reporter.match "MATCH: #{extractions.inspect}"
            break if(!multi_match)
          end
        end

        if (!foundExtractions)
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
