class HeadMusic::Content::Flow
  # Validates and coerces raw schema values into domain objects for the
  # HashDeserializer. Every method takes the raw value and the path it came
  # from, returning a validated object or raising ArgumentError with that path
  # context. Stateless: it holds no reference to the source hash, so the
  # deserializer stays responsible for *where* values come from and this class
  # for *what* a value is allowed to be.
  class SchemaValues
    include SchemaValidation

    delegate :staff_system, :staff, to: :staff_system_values
    delegate :voice_event_sounds, :voice_event_syllables, :catalog_keys, :note_dynamic, to: :voice_event_values

    # Position silently coerces garbage strings to "0:1:000", which would
    # mislocate content with no error, so the shape is validated up front.
    # Accepts "bar", "bar:count", "bar:count:tick", or "bar:count:tick:subtick"
    # with non-negative parts -- the four fields Position#code can emit.
    def position(value, path)
      return nil if value.nil?

      unless value.is_a?(String) && value.match?(/\A\d+(:\d+){0,3}\z/)
        raise ArgumentError, "#{path}: unknown position #{value.inspect}"
      end
      value
    end

    def key_signature(value, path)
      return nil if value.nil?

      known_key_signature(value, "key signature", path)
    end

    def meter(value, path)
      return nil if value.nil?

      meter = attempt { HeadMusic::Rudiment::Meter.get(value) }
      unless meter&.top_number&.positive? && meter.bottom_number.positive?
        raise ArgumentError, "#{path}: unknown meter #{value.inspect}"
      end
      meter
    end

    def rhythmic_value(value, path)
      rhythmic_value = HeadMusic::Rudiment::RhythmicValue.get(value)
      unless valid_rhythmic_value?(rhythmic_value)
        raise ArgumentError, "#{path}: unknown rhythmic value #{value.inspect}"
      end
      rhythmic_value
    end

    # A tempo serializes as its two parts rather than as a "quarter = 72"
    # string, because Tempo.get reads the number by stripping non-digits and so
    # would turn 72.5 into 725.
    def tempo(value, path)
      return nil if value.nil?

      ensure_kind!(value, Hash, "tempo", path)
      beats_per_minute = value["beats_per_minute"]
      raise ArgumentError, "#{path}: beats_per_minute must be a positive number, got #{beats_per_minute.inspect}" unless positive_number?(beats_per_minute)

      beat_value = rhythmic_value(value["beat_value"], "#{path}.beat_value")
      HeadMusic::Rudiment::Tempo.new(beat_value.to_s, beats_per_minute)
    end

    # An optional list of {"position" => ..., "level" => ...} hashes, answered
    # as [position, level] pairs.
    def dynamic_events(values, path)
      each_optional_element(values, "dynamic_events", path, &method(:dynamic_event))
    end

    # An optional list of {"kind" => ..., "from" => ..., "to" => ...} hashes,
    # answered as [kind, from, to].
    def spans(values, path)
      each_optional_element(values, "spans", path, &method(:span))
    end

    def bar_number(bar_hash, index, path = "bars")
      number = bar_hash["number"]
      unless number.is_a?(Integer) && number >= 0
        raise ArgumentError, "#{path}[#{index}]: bar number must be an Integer of at least 0, got #{number.inspect}"
      end
      number
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

      HeadMusic::Content::Flow::Timeline.tonal_context_of(known_key_signature(value, "tonal context", path))
    end

    def instrument(value, path)
      return nil if value.nil?

      instrument = HeadMusic::Instruments::Instrument.get(value)
      raise ArgumentError, "#{path}: unknown instrument #{value.inspect}" if instrument.nil?

      instrument
    end

    def player(value, players, path)
      return nil if value.nil?
      return players[value] if value.is_a?(Integer) && value.between?(0, players.length - 1)

      raise ArgumentError, "#{path}: unknown player index #{value.inspect} (#{players.length} part players)"
    end

    private

    def staff_system_values
      @staff_system_values ||= StaffSystemValues.new(self)
    end

    def voice_event_values
      @voice_event_values ||= VoiceEventValues.new
    end

    # KeySignature.get returns a hollow object (nil tonic_spelling) for
    # garbage rather than nil, so presence of the tonic is the real check.
    def known_key_signature(value, label, path)
      key_signature = attempt { HeadMusic::Rudiment::KeySignature.get(value) }
      raise ArgumentError, "#{path}: unknown #{label} #{value.inspect}" unless key_signature&.tonic_spelling

      key_signature
    end

    def positive_number?(value)
      value.is_a?(Numeric) && value.positive?
    end

    # RhythmicValue.get returns a hollow object (nil unit) for garbage rather
    # than nil, and a tied tail can be hollow while the head parses, so the
    # whole tie chain is checked.
    def valid_rhythmic_value?(rhythmic_value)
      return false unless rhythmic_value.is_a?(HeadMusic::Rudiment::RhythmicValue)
      return false unless rhythmic_value.unit

      tied_value = rhythmic_value.tied_value
      tied_value.nil? || valid_rhythmic_value?(tied_value)
    end

    def dynamic_event(value, path)
      ensure_kind!(value, Hash, "dynamic event", path)
      position = position(value["position"], path)
      raise ArgumentError, "#{path}: a dynamic event needs a position" if position.nil?

      level = catalog_value(value["level"], HeadMusic::Rudiment::Dynamic, path)
      raise ArgumentError, "#{path}: level must be a dynamic level, got #{value["level"].inspect}" unless level.level?

      [position, level]
    end

    def span(value, path)
      ensure_kind!(value, Hash, "span", path)
      kind = catalog_value(value["kind"], HeadMusic::Rudiment::SpanKind, "#{path}.kind")
      ends = %w[from to].map do |key|
        position(value[key], "#{path}.#{key}") || raise(ArgumentError, "#{path}: a span needs a #{key} position")
      end
      [kind, *ends]
    end
  end
end
