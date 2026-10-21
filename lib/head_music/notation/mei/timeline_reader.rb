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

    private

    def keys
      @keys ||= downbeat_values(@score.measures) { |measure| measure.key.key_signature(measure: measure.number) }
    end

    def tempos
      @tempos ||= downbeat_values(@score.measures.first(1), &:tempo)
    end
  end
end
