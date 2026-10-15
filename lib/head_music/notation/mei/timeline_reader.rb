module HeadMusic::Notation::MEI
  # Reads the flow's timeline from the score's measures: the meters from the
  # bars, the key in force at each measure, and the tempo on its downbeat.
  # Each opens the flow, the scoreDef's @midi.bpm standing for the opening
  # tempo where no <tempo> states one, and changes it at a later downbeat
  # only where it differs from what is in force, so that a restatement makes
  # no change. A key or tempo in the second half of a split bar falls
  # mid-bar, so it is skipped.
  class TimelineReader
    def initialize(score, bar_map, opening)
      @score = score
      @bar_map = bar_map
      @opening = opening
    end

    def opening
      first = @bar_map.first_bar
      {key_signature: keys[first], meter: @bar_map.meter_at(first), tempo: tempos[first] || @opening.tempo}
    end

    def apply(flow)
      @bar_map.bar_numbers.drop(1).each do |bar|
        meter = @bar_map.meter_at(bar)
        flow.change_meter(bar, meter) unless flow.meter_at(bar) == meter
        change_key(flow, bar, keys[bar]) if keys[bar]
        tempo = tempos[bar]
        flow.change_tempo(bar, tempo) if tempo && !same_tempo?(flow.tempo_at(bar), tempo)
      end
    end

    private

    def change_key(flow, bar, key_signature)
      event = flow.timeline.key_signature_event_at(bar)
      fifths = HeadMusic::Content::Flow::Timeline.fifths_of(key_signature)
      return if event.signature == fifths && event.key_signature.name == key_signature.name

      flow.change_key_signature(bar, key_signature)
    end

    def same_tempo?(tempo, other)
      tempo.beat_value == other.beat_value && tempo.beats_per_minute == other.beats_per_minute
    end

    def keys
      @keys ||= downbeat_values { |measure| measure.key.key_signature(measure: measure.number) }
    end

    def tempos
      @tempos ||= downbeat_values(&:tempo)
    end

    # By bar, the value the first measure on its downbeat states.
    def downbeat_values
      @score.measures.each_with_object({}) do |measure, values|
        next unless @bar_map.shift(measure.index).zero? || measure.index.zero?

        values[@bar_map.bar_number(measure.index)] ||= yield(measure)
      end
    end
  end
end
