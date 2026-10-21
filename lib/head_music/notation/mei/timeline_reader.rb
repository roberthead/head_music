module HeadMusic::Notation::MEI
  # Reads the flow's timeline from the score's measures: the meters from the
  # bars, symbols included, the key in force at each measure, and the opening
  # tempo on the first downbeat, the scoreDef's @midi.bpm standing for it
  # where no <tempo> states one. A key in the second half of a split bar falls
  # mid-bar, so it is skipped. Later tempos are read with the other tempo
  # marks, by TempoMarkReader, once the voices are placed.
  class TimelineReader < HeadMusic::Notation::TimelineReading
    def initialize(score, bar_map, opening)
      super(bar_map)
      @score = score
      @opening = opening
    end

    def opening
      opening = super
      opening.merge(tempo: opening[:tempo] || @opening.tempo)
    end

    # A meter's symbol changes where it does, though the meter stays equal.
    def apply(flow)
      super
      @bar_map.bar_numbers.drop(1).each do |bar|
        meter = @bar_map.meter_at(bar)
        flow.change_meter(bar, meter) unless flow.meter_at(bar).symbol == meter.symbol
      end
    end

    private

    def keys
      @keys ||= downbeat_values(@score.measures) { |measure| measure.key.key_signature(measure: measure.number) }
    end

    def tempos
      @tempos ||= downbeat_values(@score.measures.first(1), &:tempo)
    end
  end
end
