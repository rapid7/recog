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

  # @param path [String]
  def initialize(path)
    @match_key = nil
    @path = path
    @fingerprints = []

    parse_fingerprints
  end

  # @return [void]
  def parse_fingerprints
    xml = nil

    File.open(self.path, "rb") do |fd|
      xml = Nokogiri::XML(fd.read(fd.stat.size))
    end

    raise "#{self.path} is invalid XML: #{xml.errors.join(',')}" unless xml.errors.empty?

    xml.xpath("/fingerprints").each do |fbase|
      if fbase['matches']
        @match_key = fbase['matches'].to_s
      end
    end

    unless @match_key
      @match_key = File.basename(self.path).sub(/\.xml$/, '')
    end

    xml.xpath("/fingerprints/fingerprint").each do |fprint|
      @fingerprints << Fingerprint.new(fprint)
    end

    xml = nil
  end
end
end
