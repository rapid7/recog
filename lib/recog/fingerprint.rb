module Recog

# A fingerprint that can be {#match matched} against a particular kind of
# fingerprintable data, e.g. an HTTP `Server` header
class Fingerprint
  require 'recog/fingerprint/regexp_factory'
  require 'recog/fingerprint/test'

  # A human readable name describing this fingerprint
  # @return (see #parse_description)
  attr_reader :name

  # Regular expression pulled from the {DB} xml file.
  #
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
    @params = {}
    @tests = []

    parse_examples(xml)
    parse_params(xml)
  end

  # Attempt to match the given string.
  #
  # @param match_string [String]
  # @return [Hash,nil] Keys will be host, service, and os attributes
  def match(match_string)
    # match_string.force_encoding('BINARY') if match_string
    match_data = @regex.match(match_string)
    return if match_data.nil?

    result = { 'matched' => @name }
    @params.each_pair do |k,v|
      pos = v[0]
      if pos == 0
        # A match offset of 0 means this param has a hardcoded value
        result[k] = v[1]
      else
        # A match offset other than 0 means the value should come from
        # the corresponding match result index
        result[k] = match_data[ pos ]
      end
    end
    return result
  end

  # Ensure all the {#tests} actually match the fingerprint and return the
  # expected capture groups.
  #
  # @yieldparam status [Symbol] One of `:warn`, `:fail`, or `:success` to
  #   indicate whether a test worked
  # @yieldparam message [String] A human-readable string explaining the
  #   `status`
  def verify_tests(&block)
    if tests.size == 0
      yield :warn, "'#{@name}' has no test cases"
    end

    tests.each do |test|
      result = match(test.content)
      if result.nil?
        yield :fail, "'#{@name}' failed to match #{test.content.inspect} with #{@regex}'"
        next
      end

      message = test
      status = :success
      # Ensure that all the attributes as provided by the example were parsed
      # out correctly and match the capture group values we expect.
      test.attributes.each do |k, v|
        if !result.has_key?(k) || result[k] != v
          message = "'#{@name}' failed to find expected capture group #{k} '#{v}'"
          status = :fail
          break
        end
      end
      yield status, message
    end
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
    element.empty? ? '' : element.first.content.to_s.gsub(/\s+/, ' ').strip
  end

  # @param xml [Nokogiri::XML::Element]
  # @return [void]
  def parse_examples(xml)
    elements = xml.xpath('example')

    elements.each do |elem|
      # convert nokogiri Attributes into a hash of name => value
      attrs = elem.attributes.values.reduce({}) { |a,e| a.merge(e.name => e.value) }
      @tests << Test.new(elem.content, attrs)
    end

    nil
  end

  # @param xml [Nokogiri::XML::Element]
  # @return [Hash<String,Array>] Keys are things like `"os.name"`, values are a two
  #   element Array. The first element is an index for the capture group that returns
  #   that thing. If the index is 0, the second element is a static value for
  #   that thing; otherwise it is undefined.
  def parse_params(xml)
    @params = {}.tap do |h|
      xml.xpath('param').each do |param|
        name  = param['name']
        pos   = param['pos'].to_i
        value = param['value'].to_s
        h[name] = [pos, value]
      end
    end

    nil
  end

end
end
