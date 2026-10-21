# A module for visual music notation
module HeadMusic::Notation
  # Reads a flow's timeline from a bar map and the keys and tempos a format
  # states by bar on its downbeats. Each opens the flow and changes it at a
  # later downbeat only where it differs from what is in force, so that a
  # restatement makes no change. A meter's symbol and a tempo's text count,
  # so a change to either alone is a change. Subclasses answer +keys+ and +tempos+.
  class TimelineReading
    def initialize(bar_map)
      @bar_map = bar_map
    end

    def opening
      first = @bar_map.first_bar
      {key_signature: keys[first], meter: @bar_map.meter_at(first), tempo: tempos[first]}
    end

    # A new flow opened and changed as the timeline reads, with the score's
    # identity.
    def flow(identity)
      HeadMusic::Content::Flow.new(name: identity.name, work: identity.work, composer: identity.composer, **opening).tap do |flow|
        apply(flow)
      end
    end

    def apply(flow)
      @bar_map.bar_numbers.drop(1).each do |bar|
        meter = @bar_map.meter_at(bar)
        flow.change_meter(bar, meter) unless same_meter?(flow.meter_at(bar), meter)
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

    def same_meter?(meter, other)
      meter == other && meter.symbol == other.symbol
    end

    def same_tempo?(tempo, other)
      tempo.beat_value == other.beat_value && tempo.beats_per_minute == other.beats_per_minute && tempo.text == other.text
    end

    # By bar, the first value the measures state on a downbeat.
    def downbeat_values(measures)
      measures.each_with_object({}) do |measure, values|
        next unless @bar_map.shift(measure.index).zero? || measure.index.zero?

        values[@bar_map.bar_number(measure.index)] ||= yield(measure)
      end
    end
  end
end
