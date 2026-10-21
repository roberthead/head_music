class HeadMusic::Content::Flow
  # The timeline corner of SchemaValues: a meter and its symbol, a key
  # signature and its interpretation, a tempo and its text, and the tempo
  # ramps, "a tempo" points, and fermatas. Split from the scalar validators,
  # as StaffSystemValues was, because the two together outgrew one class.
  class TimelineValues
    include SchemaValidation

    # @param values [SchemaValues] for positions, their ranges, and rhythmic values
    def initialize(values)
      @values = values
    end

    def key_signature(value, path)
      return nil if value.nil?

      known_key_signature(value, "key signature", path)
    end

    # Sharps positive, flats negative, and unbounded: a theoretical key such as
    # G sharp major counts each double accidental twice and reaches eight.
    def fifths(value, path)
      raise ArgumentError, "#{path}: signature must be an Integer of fifths, got #{value.inspect}" unless value.is_a?(Integer)

      value
    end

    # A Key, a Mode, or -- for a scale type neither can hold -- a KeySignature.
    # Round-tripped by name, which is what each of the three parses back from.
    def tonal_context(value, path)
      return nil if value.nil?

      HeadMusic::Time::KeySignatureEvent.tonal_context_of(known_key_signature(value, "tonal context", path))
    end

    # A symbol is written beside the numerals it stands for, and must agree
    # with them.
    def meter(value, path, symbol = nil)
      return nil if value.nil?

      meter = attempt { HeadMusic::Rudiment::Meter.get(value) }
      unless meter&.top_number&.positive? && meter.bottom_number.positive?
        raise ArgumentError, "#{path}: unknown meter #{value.inspect}"
      end
      symbol.nil? ? meter : meter_with_symbol(meter, symbol, path)
    end

    # A tempo serializes as its two parts rather than as a "quarter = 72"
    # string, because Tempo.get reads the number by stripping non-digits and so
    # would turn 72.5 into 725.
    def tempo(value, path)
      return nil if value.nil?

      ensure_kind!(value, Hash, "tempo", path)
      beats_per_minute = value["beats_per_minute"]
      raise ArgumentError, "#{path}: beats_per_minute must be a positive number, got #{beats_per_minute.inspect}" unless positive_number?(beats_per_minute)

      beat_value = values.rhythmic_value(value["beat_value"], "#{path}.beat_value")
      HeadMusic::Rudiment::Tempo.new(
        beat_value.to_s, beats_per_minute,
        text: tempo_text(value["text"], path),
        metronome_mark: boolean_value(value.fetch("metronome_mark", true), "#{path}.metronome_mark: ")
      )
    end

    # An optional list of {"from", "to"} hashes, with an optional target
    # "tempo" and "text", answered as [from, to, tempo, text].
    def tempo_ramps(items, path)
      each_optional_element(items, "tempo_ramps", path, &method(:tempo_ramp))
    end

    # An optional list of {"position", "text"} hashes, answered as
    # [position, text]. A point written with no "text" says "a tempo".
    def a_tempos(items, path)
      each_optional_element(items, "a_tempos", path, &method(:a_tempo))
    end

    # An optional list of {"from", "to", "stretch"} hashes, answered as
    # [from, to, stretch].
    def fermatas(items, path)
      each_optional_element(items, "fermatas", path, &method(:fermata))
    end

    private

    attr_reader :values

    # KeySignature.get returns a hollow object (nil tonic_spelling) for
    # garbage rather than nil, so presence of the tonic is the real check.
    def known_key_signature(value, label, path)
      key_signature = attempt { HeadMusic::Rudiment::KeySignature.get(value) }
      raise ArgumentError, "#{path}: unknown #{label} #{value.inspect}" unless key_signature&.tonic_spelling

      key_signature
    end

    def meter_with_symbol(meter, symbol, path)
      symbolic = attempt { HeadMusic::Rudiment::Meter.for_symbol(symbol) } if symbol.is_a?(String)
      raise ArgumentError, "#{path}: unknown meter symbol #{symbol.inspect}" unless symbolic
      raise ArgumentError, "#{path}: the #{symbol} symbol is #{symbolic}, not #{meter}" unless symbolic == meter

      symbolic
    end

    def tempo_text(text, path)
      return nil if text.nil?
      raise ArgumentError, "#{path}.text: tempo text must be a non-empty String, got #{text.inspect}" unless non_empty_string?(text)

      text
    end

    def positive_number?(value)
      value.is_a?(Numeric) && value.positive?
    end

    def tempo_ramp(value, path)
      ensure_kind!(value, Hash, "tempo ramp", path)
      [*values.ends(value, "tempo ramp", path), tempo(value["tempo"], "#{path}.tempo"), tempo_text(value["text"], path)]
    end

    def a_tempo(value, path)
      ensure_kind!(value, Hash, "a tempo", path)
      position = values.position(value["position"], path) || raise(ArgumentError, "#{path}: an a tempo needs a position")
      [position, tempo_text(value.fetch("text", "a tempo"), path)]
    end

    def fermata(value, path)
      ensure_kind!(value, Hash, "fermata", path)
      stretch = value.fetch("stretch", HeadMusic::Time::Fermata::DEFAULT_STRETCH)
      raise ArgumentError, "#{path}.stretch: must be a number of at least 1, got #{stretch.inspect}" unless stretch?(stretch)

      [*values.ends(value, "fermata", path), stretch]
    end

    def stretch?(value)
      value.is_a?(Numeric) && value >= 1
    end
  end
end
