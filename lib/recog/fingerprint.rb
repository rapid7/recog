module Recog
class Fingerprint
  attr_reader :name, :regex, :params, :tests

  def initialize(xml)
    @name   = description(xml)
    @regex  = create_regexp(xml)
    @params = parse_params(xml)
    @tests  = examples(xml)
  end

  private

  def description(xml)
    element = xml.xpath('description')
    element.empty? ? '' : element.first.content
  end

  def create_regexp(xml)
    pattern = xml['pattern']
    flags   = xml['flags'].to_s.split(',')
    RegexpFactory.build(pattern, flags)
  end

  def parse_params(xml)
    {}.tap do |h|
      xml.xpath('param').each do |param|
        name  = param['name']
        pos   = param['pos'].to_i
        value = param['value'].to_s
        h[name] = [pos, value]
      end
    end
  end

  def examples(xml)
    xml.xpath('example').collect(&:content)
  end

  module RegexpFactory
    def self.build(pattern, flags)
      options = build_options(flags)
      Regexp.new(pattern, options)
    end

    def self.build_options(flags)
      rflags = Regexp::NOENCODING
      flags.each do |flag|
        case flag
        when 'REG_DOT_NEWLINE', 'REG_LINE_ANY_CRLF'
          rflags |= Regexp::MULTILINE
        when 'REG_ICASE'
          rflags |= Regexp::IGNORECASE
        end
      end
      rflags
    end
  end
end
end
