# A module for music rudiments
module HeadMusic::Rudiment; end

# A symbol is a mark or sign that signifies a particular rudiment of music
class HeadMusic::Rudiment::MusicalSymbol
  attr_reader :ascii, :unicode, :html_entity

  def initialize(ascii: nil, unicode: nil, html_entity: nil)
    @ascii = ascii
    @unicode = unicode
    @html_entity = html_entity
  end
end
