
class Recog::Fingerprint::Test
  attr_accessor :content
  attr_accessor :attributes
  def initialize(content, attributes=[])
    @content = content
    @attributes = attributes
  end

  def to_s
    content
  end
end
