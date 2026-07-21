# A module for musical content
module HeadMusic::Content; end

# A sung syllable attached to a Placement for one verse. Only the minimal
# linguistic fact is stored: the text, its verse number, and whether the word
# continues onto the next sung note (hyphen_after). The MusicXML `syllabic`
# value (single/begin/middle/end) is derived from these at render time rather
# than stored, and melisma is represented by the absence of a syllable on the
# following placements, so nothing here encodes it.
class HeadMusic::Content::Syllable
  attr_reader :text, :verse, :hyphen_after

  def initialize(text, verse: 1, hyphen_after: false)
    @text = text.to_s
    @verse = Integer(verse)
    @hyphen_after = !!hyphen_after
    freeze
  end

  def hyphen_after?
    hyphen_after
  end

  def to_h
    hash = {"text" => text}
    hash["verse"] = verse unless verse == 1
    hash["hyphen_after"] = true if hyphen_after
    hash
  end

  def self.from_h(hash)
    new(hash["text"], verse: hash.fetch("verse", 1), hyphen_after: hash.fetch("hyphen_after", false))
  end

  def ==(other)
    other.is_a?(self.class) && to_h == other.to_h
  end
end
