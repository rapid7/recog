module Recog
class Matcher
  attr_reader :fingerprints, :reporter, :multi_match

  # @param fingerprints Array of [Recog::Fingerprint] The list of fingerprints from the Recog DB to find possible matches.
  # @param reporter [Recog::MatchReporter] The reporting structure that holds the matches and fails
  # @param multi_match [Boolean] specifies whether or not to use multi-match (true) or not (false)
  def initialize(fingerprints, reporter, multi_match)
    @fingerprints = fingerprints
    @reporter = reporter
    @multi_match = multi_match
  end

  # @param banners_file [String] The source of banners to attempt to match against the Recog DB.
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
        found_extractions = false

        fingerprints.each do |fp|
          extractions = fp.match(line)
          if extractions
            found_extractions = true
            extractions['data'] = line
            reporter.match "MATCH: #{extractions.inspect}"
            break unless multi_match
          end
        end

        unless found_extractions
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
