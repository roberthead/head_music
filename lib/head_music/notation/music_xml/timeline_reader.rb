# A namespace for MusicXML-notation reading helpers
module HeadMusic::Notation::MusicXML
  # Reads the flow's timeline: the meters from the bars, the keys from the
  # first part, since the timeline holds one key, and the tempos from any
  # part, the first in each bar winning. A key or tempo in the second half of
  # a split bar falls mid-bar, so it is skipped.
  class TimelineReader < HeadMusic::Notation::TimelineReading
    def initialize(readings, bar_map)
      super(bar_map)
      @readings = readings
    end

    # A signature with no <mode> reads as its major key, as kern reads one.
    def self.key_signature(fifths, mode, **where)
      tonal_context = KeyMapper.tonal_context(fifths, mode) || KeyMapper.tonal_context(fifths, "major")
      raise UnsupportedFeatureError.new("A key of #{fifths} fifths is not supported", **where) unless tonal_context

      HeadMusic::Rudiment::KeySignature.get(tonal_context.name)
    end

    private

    def keys
      reading = @readings.first
      @keys ||= downbeat_values(reading.measures) do |measure|
        fifths, mode = measure.key
        fifths && self.class.key_signature(fifths, mode, measure: measure.number, part: reading.id)
      end
    end

    def tempos
      @tempos ||= downbeat_values(@readings.flat_map(&:measures), &:tempo)
    end
  end
end
