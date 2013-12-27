module Recog
class FingerprintDB
  require 'nokogiri'

  attr_accessor :service_name, :path, :fingerprints

  def initialize(service_name, path)
    self.service_name = service_name
    self.path = path
    self.fingerprints = []
    parse_fingerprints
  end

  def parse_fingerprints
    xml = nil
    File.open(self.path, "rb") do |fd|
      xml = Nokogiri::XML( fd.read(fd.stat.size))
    end

    xml.xpath("//fingerprint").each do |fprint|
      fingerprints << Fingerprint.new(fprint)
    end
    xml = nil
  end
end

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
      xml.xpath('param').each do |e|
        name  = e['name']
        pos   = e['pos'].to_i
        value = e['value'].to_s
        h[name] = [pos, value]
      end
    end
  end

  def examples(xml)
    xml.xpath('example').collect(&:content)
  end
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
