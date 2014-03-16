module Recog
class Nizer
  
  @@db_manager = nil

  def self.match(match_key, match_string)
    match_string = match_string.to_s.unpack("C*").pack("C*")
    @@db_manager ||= Recog::DBManager.new
    @@db_manager.databases.each do |db|
      next unless db.match_key == match_key
      db.fingerprints.each do |fprint|
        m = fprint.regex.match(match_string)
        next unless m
        result = { 'matched' => fprint.name }
        fprint.params.each_pair do |k,v|
          if v[0] == 0
            result[k] = v[1]
          else
            result[k] = m[ v[0] ]
          end
        end
        return result  
      end
    end
    nil
  end
 
end
end