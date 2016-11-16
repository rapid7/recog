module Recog

# A collection of {Fingerprint fingerprints} for matching against a particular
# kind of fingerprintable data, e.g. an HTTP `Server` header
class DB
  require 'nokogiri'
  require 'recog/fingerprint'

  # @return [String]
  attr_reader :path

  # @return [Array<Fingerprint>] {Fingerprint} objects that can be matched
  #   against strings that make sense for the {#match_key}
  attr_reader :fingerprints

  # @return [String] Taken from the `fingerprints/matches` element, or
  #   defaults to the basename of {#path} without the `.xml` extension.
  attr_reader :match_key

  # @return [String] Taken from the `fingerprints/protocol` element, or
  #   defaults to an empty string
  attr_reader :protocol

  # @return [String] Taken from the `fingerprints/database_type` element
  #   defaults to an empty string
  attr_reader :database_type

  # @return [Integer] Taken from the `fingerprints/priority` element,
  #   defaults to 100.  Used when ordering databases, lowest numbers
  #   first.
  attr_reader :priority

  # Default Fingerprint database priority when it isn't specified in file
  DEFAULT_FP_DB_PRIORITY = 100

  # @param path [String]
  def initialize(path)
    @match_key = nil
    @protocol = ''
    @database_type = ''
    @priority = DEFAULT_FP_DB_PRIORITY
    @path = path
    @fingerprints = []

    parse_fingerprints
  end

  # @return [void]
  def parse_fingerprints
    xml = nil

    File.open(self.path, 'rb') do |fd|
      xml = Nokogiri::XML(fd.read(fd.stat.size))
    end

    raise "#{self.path} is invalid XML: #{xml.errors.join(',')}" unless xml.errors.empty?

    xml.xpath('/fingerprints').each do |fbase|

      @match_key = fbase['matches'].to_s if fbase['matches']
      @protocol  = fbase['protocol'].to_s if fbase['protocol']
      @database_type = fbase['database_type'].to_s if fbase['database_type']
      @priority  = fbase['priority'].to_i if fbase['priority']

    end

    @match_key = File.basename(self.path).sub(/\.xml$/, '') unless @match_key

    xml.xpath('/fingerprints/fingerprint').each do |fprint|
      @fingerprints << Fingerprint.new(fprint, @match_key, @protocol)
    end

    xml = nil
  end
end
end
