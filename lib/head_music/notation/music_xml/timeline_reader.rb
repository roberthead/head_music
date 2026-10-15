# A namespace for MusicXML-notation reading helpers
module HeadMusic::Notation::MusicXML
  # Reads the flow's timeline from the parts: the opening key from the first
  # part, and the opening meter from the bars.
  class TimelineReader
    def initialize(readings, bar_map)
      @readings = readings
      @bar_map = bar_map
    end

    def opening
      {key_signature: opening_key_signature, meter: @bar_map.meter_at(@bar_map.first_bar)}
    end

    # A signature with no <mode> reads as its major key, as kern reads one.
    def self.key_signature(fifths, mode, **where)
      tonal_context = KeyMapper.tonal_context(fifths, mode) || KeyMapper.tonal_context(fifths, "major")
      raise UnsupportedFeatureError.new("A key of #{fifths} fifths is not supported", **where) unless tonal_context

      HeadMusic::Rudiment::KeySignature.get(tonal_context.name)
    end

    private

    def opening_key_signature
      measure = @readings.first.measures.first
      fifths, mode = measure.key
      return unless fifths

      self.class.key_signature(fifths, mode, measure: measure.number, part: @readings.first.id)
    end
  end
end
