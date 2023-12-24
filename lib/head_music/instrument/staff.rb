class HeadMusic::Instrument::Staff
  DEFAULT_CLEF = "treble_clef"

  attr_reader :staff_configuration, :attributes

  def initialize(staff_configuration, attributes)
    @staff_configuration = staff_configuration
    @attributes = attributes || {}
  end

  def clef
    HeadMusic::Clef.get(smart_clef_key)
  end

  def smart_clef_key
    "#{attributes["clef"]}_clef".gsub(/_clef_clef$/, "_clef")
  end

  def sounding_transposition
    attributes["sounding_transposition"] || 0
  end

  def name_key
    attributes["name_key"]
  end

  def name
    name_key.to_s.tr("_", " ")
  end
end
