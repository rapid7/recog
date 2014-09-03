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

  # Attempt to match the given string.
  #
  # @param match_string [String]
  # @return [Hash,nil]
  def match(match_string)
    m = @regex.match(match_string)
    return if m.nil?

    result = { 'matched' => @name }
    @params.each_pair do |k,v|
      if v[0] == 0
        # A match offset of 0 means this param has a hardcoded value
        result[k] = v[1]
      else
        result[k] = m[ v[0] ]
      end
    end
    return result
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
  # @return [Hash]
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
