# frozen_string_literal: true

class HeadMusic::Staff
  DEFAULT_LINE_COUNT = 5

  attr_reader :default_clef, :line_count, :instrument
  alias_method :clef, :default_clef

  def initialize(default_clef, instrument: nil, line_count: nil)
    @default_clef = HeadMusic::Clef.get(default_clef)
    @line_count = line_count || DEFAULT_LINE_COUNT
    @instrument = HeadMusic::Instrument.get(instrument) if instrument
  end
end
