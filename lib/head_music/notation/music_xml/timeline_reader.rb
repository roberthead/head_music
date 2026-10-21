# A namespace for MusicXML-notation reading helpers
module HeadMusic::Notation::MusicXML
  # Reads the flow's timeline: the meters from the bars, with their symbols,
  # the keys from the first part, since the timeline holds one key, and the
  # opening tempo. A key in the second half of a split bar falls mid-bar, so
  # it is skipped. TempoReader reads the later tempos once the flow's
  # fermatas are known.
  class TimelineReader < HeadMusic::Notation::TimelineReading
    def initialize(readings, bar_map, tempo_reader)
      super(bar_map)
      @readings = readings
      @tempo_reader = tempo_reader
    end

    # A meter that differs only in its symbol is equal to the one in force,
    # so it is changed here.
    def apply(flow)
      super
      @bar_map.bar_numbers.drop(1).each do |bar|
        meter = @bar_map.meter_at(bar)
        flow.change_meter(bar, meter) unless flow.meter_at(bar).symbol == meter.symbol
      end
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
      @tempos ||= {@bar_map.first_bar => @tempo_reader.opening}
    end
  end
end
