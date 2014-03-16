module Recog
class DB
  require 'nokogiri'
  require 'recog/fingerprint'

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
end