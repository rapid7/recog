module Recog

# A fingerprint that can be matched against a particular kind of
# fingerprintable data, e.g. an HTTP `Server` header
class Fingerprint
  require 'recog/fingerprint/regexp_factory'

  # A human readable name describing this fingerprint
  # @return (see #parse_description)
  attr_reader :name

  # @see #create_regexp
  # @return [Regexp] the Regexp to try when calling {#match}
  attr_reader :regex

  # Collection of indexes for capture groups created by {#match}
  #
  # @return (see #parse_params)
  attr_reader :params

  # Collection of example strings that should {#match} our {#regex}
  #
  # @return (see #parse_examples)
  attr_reader :tests

  # @param xml [Nokogiri::XML::Element]
  def initialize(xml)
    @name   = parse_description(xml)
    @regex  = create_regexp(xml)
    @params = parse_params(xml)
    @tests  = parse_examples(xml)
  end

  # Attempt to match the given string.
  #
  # @param match_string [String]
  # @return [Hash,nil] Keys will be host, service, and os attributes
  def match(match_string)
    match_data = @regex.match(match_string)
    return if match_data.nil?

    result = { 'matched' => @name }
    @params.each_pair do |k,v|
      if v[0] == 0
        # A match offset of 0 means this param has a hardcoded value
        result[k] = v[1]
      else
        result[k] = match_data[ v[0] ]
      end
    end
    return result
  end

  private

  # @param xml [Nokogiri::XML::Element]
  # @return [Regexp]
  def create_regexp(xml)
    pattern = xml['pattern']
    flags   = xml['flags'].to_s.split(',')
    RegexpFactory.build(pattern, flags)
  end

  # @param xml [Nokogiri::XML::Element]
  # @return [String] Contents of the source XML's `description` tag
  def parse_description(xml)
    element = xml.xpath('description')
    element.empty? ? '' : element.first.content
  end

  # @param xml [Nokogiri::XML::Element]
  # @return [Array<String>]
  def parse_examples(xml)
    xml.xpath('example').collect(&:content)
  end

  # @param xml [Nokogiri::XML::Element]
  # @return [Hash<String,Array>] Keys are things like os.name, values are a two
  #   element Array. The first element is an index for the capture group that returns
  #   that thing. If the index is 0, the second element is a static value for
  #   that thing; otherwise it is undefined.
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

end
end
