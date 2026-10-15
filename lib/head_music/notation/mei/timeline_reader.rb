module HeadMusic::Notation::MEI
  # Reads the flow's timeline: the key, meter, and tempo it opens with.
  class TimelineReader
    def initialize(score, bar_map, opening)
      @score = score
      @bar_map = bar_map
      @opening = opening
    end

    def opening
      {
        key_signature: @opening.key.key_signature(measure: @score.measures.first&.number),
        meter: @bar_map.meter_at(@bar_map.first_bar),
        tempo: @opening.tempo
      }
    end

    def apply(flow)
    end
  end
end
