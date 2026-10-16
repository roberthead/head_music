module HeadMusic::Notation::MEI
  # Reads the flow's timeline from the score's measures: the meters from the
  # bars, the key in force at each measure, and the tempo on its downbeat,
  # the scoreDef's @midi.bpm standing for the opening tempo where no <tempo>
  # states one. A key or tempo in the second half of a split bar falls
  # mid-bar, so it is skipped.
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
      @tempos ||= downbeat_values(@score.measures, &:tempo)
    end
  end
end
