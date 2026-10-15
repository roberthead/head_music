# A namespace for MusicXML-notation reading helpers
module HeadMusic::Notation::MusicXML
  # Reads the flow's timeline: the meters from the bars, the keys from the
  # first part, since the timeline holds one key, and the tempos from any
  # part, the first in each bar winning. Each opens the flow, and changes it
  # at a later downbeat only where it differs from what is in force. A key or
  # tempo in the second half of a split bar falls mid-bar, so it is skipped.
  class TimelineReader
    def initialize(readings, bar_map)
      @readings = readings
      @bar_map = bar_map
    end

    def opening
      first = @bar_map.first_bar
      {key_signature: keys[first], meter: @bar_map.meter_at(first), tempo: tempos[first]}
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

    # A signature with no <mode> reads as its major key, as kern reads one.
    def self.key_signature(fifths, mode, **where)
      tonal_context = KeyMapper.tonal_context(fifths, mode) || KeyMapper.tonal_context(fifths, "major")
      raise UnsupportedFeatureError.new("A key of #{fifths} fifths is not supported", **where) unless tonal_context

      HeadMusic::Rudiment::KeySignature.get(tonal_context.name)
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
      @keys ||= downbeat_values([@readings.first]) do |reading, measure|
        fifths, mode = measure.key
        fifths && self.class.key_signature(fifths, mode, measure: measure.number, part: reading.id)
      end
    end

    def tempos
      @tempos ||= downbeat_values(@readings) { |_reading, measure| measure.tempo }
    end

    # By bar, the first value any of the readings states on a downbeat.
    def downbeat_values(readings)
      readings.each_with_object({}) do |reading, values|
        reading.measures.each do |measure|
          next unless @bar_map.shift(measure.index).zero? || measure.index.zero?

          bar = @bar_map.bar_number(measure.index)
          values[bar] ||= yield(reading, measure)
        end
      end
    end
  end
end
