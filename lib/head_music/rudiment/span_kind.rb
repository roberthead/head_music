# A module for music rudiments
module HeadMusic::Rudiment; end

# A SpanKind is a kind of marking that runs from one point in the music to a
# later one, such as a slur or a phrase mark. Its rules are data, so a new
# kind is a catalog entry rather than a new shape.
class HeadMusic::Rudiment::SpanKind
  include HeadMusic::Rudiment::KeyedCatalog

  load_catalog(File.expand_path("span_kinds.yml", __dir__), "span_kinds")

  attr_reader :family, :anchor, :extent, :owners

  def initialize(name_key, record)
    super
    @family = record.fetch("family")
    @anchor = record.fetch("anchor")
    @extent = record.fetch("extent")
    @owners = record.fetch("owners").freeze
  end

  # A slur needs sounding notes at its ends; a phrase may begin or end on a
  # rest; a kind anchored at positions, such as a hairpin, may end
  # anywhere.
  def anchors_on?(voice_event)
    case anchor
    when "positions" then true
    when "voice_events" then !voice_event.nil?
    else !voice_event.nil? && !voice_event.rest?
    end
  end

  def anchor_description
    (anchor == "note_events") ? "a note" : "a note or rest"
  end

  def curve?
    family == "curve"
  end

  def hairpin?
    family == "hairpin"
  end

  def covers_last_note?
    extent == "through_note"
  end

  def held_by?(owner)
    owners.include?(owner.to_s)
  end
end
