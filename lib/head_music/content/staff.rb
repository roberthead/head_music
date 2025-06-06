# A module for musical content
module HeadMusic::Content; end

# A staff is a set of lines and spaces that provides context for a pitch
class HeadMusic::Content::Staff
  DEFAULT_LINE_COUNT = 5

  attr_reader :default_clef, :line_count, :instrument

  def initialize(default_clef_key, instrument: nil, line_count: nil)
    @default_clef = HeadMusic::Rudiment::Clef.get(default_clef_key)
    @line_count = line_count || DEFAULT_LINE_COUNT
    @instrument = HeadMusic::Instruments::Instrument.get(instrument) if instrument
  end

  def clef
    default_clef || instrument&.default_staves&.first&.clef
  end
end
