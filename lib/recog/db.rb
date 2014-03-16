module Recog
class DB
  require 'nokogiri'
  require 'recog/fingerprint'

  attr_accessor :path, :fingerprints, :match_key

  def initialize(path)
    self.path = path
    parse_fingerprints
  end

  def parse_fingerprints
    self.fingerprints = []
    xml = nil
    
    File.open(self.path, "rb") do |fd|
      xml = Nokogiri::XML( fd.read(fd.stat.size))
    end

    xml.xpath("/fingerprints").each do |fbase|
      if fbase['matches']
        self.match_key = fbase['matches'].to_s
      end
    end

    unless self.match_key
      self.match_key = File.basename(self.path).sub(/\.xml$/, '')
    end

    xml.xpath("/fingerprints/fingerprint").each do |fprint|
      fingerprints << Fingerprint.new(fprint)
    end

    xml = nil
  end
end
end