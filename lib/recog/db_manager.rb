module Recog
class DBManager
  require 'nokogiri'
  require 'recog/db'

  attr_accessor :path, :databases

  DefaultDatabasePath = File.expand_path( File.join( File.dirname(__FILE__), "..", "..", "xml") )

  def initialize(path = DefaultDatabasePath)
    self.path = path
    reload
  end

  def load_databases
    Dir[self.path + "/*.xml"].each do |dbxml|
      self.databases << DB.new(dbxml)
    end
  end

  def reload
    self.databases = []
    load_databases
  end

end
end
