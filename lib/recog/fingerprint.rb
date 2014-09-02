module Recog
class Fingerprint
  require 'recog/fingerprint/regexp_factory'

  attr_reader :name
  attr_reader :regex
  attr_reader :params
  attr_reader :tests

  # @param xml [Nokogiri::XML::Element]
  def initialize(xml)
    @name   = description(xml)
    @regex  = create_regexp(xml)
    @params = parse_params(xml)
    @tests  = examples(xml)
  end

  private

  # @param xml [Nokogiri::XML::Element]
  def description(xml)
    element = xml.xpath('description')
    element.empty? ? '' : element.first.content
  end

  # @param xml [Nokogiri::XML::Element]
  # @return [Regexp]
  def create_regexp(xml)
    pattern = xml['pattern']
    flags   = xml['flags'].to_s.split(',')
    RegexpFactory.build(pattern, flags)
  end

  # @param xml [Nokogiri::XML::Element]
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

  # @param xml [Nokogiri::XML::Element]
  def examples(xml)
    xml.xpath('example').collect(&:content)
  end

end
end
