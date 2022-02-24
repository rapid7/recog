module Recog
  class FingerprintParseError < StandardError
    attr_reader :line_number

    def initialize(msg, line_number=nil)
      @line_number = line_number
      super(msg)
    end
  end
end
