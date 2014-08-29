
module Recog
  class Fingerprint

    #
    # @example
    #   r = RegexpFactory.build("^Apache[ -]Coyote/(\d\.\d)$", "REG_ICASE")
    #   r.match("Apache-Coyote/1.1")
    #
    module RegexpFactory

      # Map strings as used in Recog XML to Fixnum values used by Regexp
      FLAG_MAP = {
        'REG_DOT_NEWLINE'   => Regexp::MULTILINE,
        'REG_LINE_ANY_CRLF' => Regexp::MULTILINE,
        'REG_ICASE'         => Regexp::IGNORECASE,
      }

      # @return [Regexp]
      def self.build(pattern, flags)
        options = build_options(flags)
        Regexp.new(pattern, options)
      end

      # Convert string flag names as used in Recog XML into a Fixnum suitable for
      # passing as the `options` parameter to `Regexp.new`
      #
      # @see FLAG_MAP
      # @param flags [Array<String>]
      # @return [Fixnum] Flags for creating a regular expression object
      def self.build_options(flags)
        flags.reduce(Regexp::NOENCODING) do |sum, flag|
          sum |= (FLAG_MAP[flag] || 0)
        end
      end
    end
  end
end

