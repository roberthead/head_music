# Namespace for instrument definitions, categorization, and configuration
module HeadMusic::Instruments; end

class HeadMusic::Instruments::Staff
  DEFAULT_CLEF = "treble_clef"

  attr_reader :staff_scheme, :attributes

  def initialize(staff_scheme, attributes)
    @staff_scheme = staff_scheme
    @attributes = attributes || {}
  end

  def clef
    HeadMusic::Rudiment::Clef.get(smart_clef_key)
  end

  def smart_clef_key
    "#{attributes["clef"]}_clef".gsub(/_clef_clef$/, "_clef")
  end

  def sounding_transposition
    attributes["sounding_transposition"] || 0
  end

  def name_key
    attributes["name_key"] || ""
  end

  def name
    name_key.to_s.tr("_", " ")
  end
end
