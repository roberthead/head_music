# A module for musical content
module HeadMusic::Content; end

# A staff is a set of lines and spaces that provides context for a pitch
class HeadMusic::Content::Staff
  DEFAULT_LINE_COUNT = 5

  attr_reader :default_clef, :line_count, :instrument

  def initialize(default_clef_key, instrument: nil, line_count: nil)
    @instrument = HeadMusic::Instruments::Instrument.get(instrument) if instrument
    begin
      @default_clef = HeadMusic::Rudiment::Clef.get(default_clef_key)
    rescue KeyError, NoMethodError
      puts("Warning: Clef '#{default_clef_key}' not found.")
      if @instrument
        puts("Using instrument clef.")
        @default_clef = @instrument.default_staves.first.clef
      else
        @default_clef = HeadMusic::Rudiment::Clef.get(:treble_clef)
      end
    end
    @line_count = line_count || DEFAULT_LINE_COUNT
  end

  def clef
    default_clef
  end
end
