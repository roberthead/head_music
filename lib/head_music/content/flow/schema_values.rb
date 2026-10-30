class HeadMusic::Content::Flow
  # Validates and coerces raw schema values into domain objects for the
  # HashDeserializer. Every method takes the raw value and the path it came
  # from, returning a validated object or raising ArgumentError with that path
  # context. Stateless: it holds no reference to the source hash, so the
  # deserializer stays responsible for *where* values come from and this class
  # for *what* a value is allowed to be.
  class SchemaValues
    include SchemaValidation

    BAR_FLAGS = %w[starts_repeat segno coda fine to_coda].freeze
    BAR_FIELDS = [*BAR_FLAGS, "ends_repeat_after_num_plays", "plays_on_passes", "barline", "rehearsal_mark", "jump"].freeze

    delegate :staff_system, :staff, to: :staff_system_values
    delegate :voice_event_sounds, :voice_event_syllables, :catalog_keys, :note_dynamic, :grace_notes, to: :voice_event_values
    delegate :meter, :key_signature, :fifths, :tonal_context, :tempo, :tempo_ramps, :a_tempos, :fermatas, to: :timeline_values

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

    def rhythmic_duration(value, path)
      HeadMusic::Rudiment::RhythmicDuration.get(value) || raise(ArgumentError, "#{path}: unknown rhythmic value #{value.inspect}")
    end

    def rhythmic_value(value, path)
      rhythmic_value = HeadMusic::Rudiment::RhythmicValue.get(value)
      unless valid_rhythmic_value?(rhythmic_value)
        raise ArgumentError, "#{path}: unknown rhythmic value #{value.inspect}"
      end
      rhythmic_value
    end

    # An optional list of {"position" => ..., "level" => ...} hashes, answered
    # as [position, level] pairs.
    def dynamic_events(values, path)
      each_optional_element(values, "dynamic_events", path, &method(:dynamic_event))
    end

    # An optional list of {"kind" => ..., "from" => ..., "to" => ...} hashes,
    # with an optional "from_grace", answered as [kind, from, to, from_grace].
    def spans(values, path)
      each_optional_element(values, "spans", path, &method(:span))
    end

    # An optional list of {"from" => ..., "to" => ..., "unit" => ...} hashes,
    # answered as [from, to, unit]. A group's ratio is its values'.
    def tuplets(values, path)
      each_optional_element(values, "tuplets", path, &method(:tuplet))
    end

    def bar_number(bar_hash, index, path = "bars")
      number = bar_hash["number"]
      unless number.is_a?(Integer) && number >= 0
        raise ArgumentError, "#{path}[#{index}]: bar number must be an Integer of at least 0, got #{number.inspect}"
      end
      number
    end

    # Answers the value a bar field's setter takes. The setters validate it,
    # except that starts_repeat= takes anything, so the flags are checked here.
    def bar_field(field, value)
      return bar_jump(value) if field == "jump"
      return boolean_value(value) if BAR_FLAGS.include?(field)

      value
    end

    def instrument(value, path)
      return nil if value.nil?

      instrument = HeadMusic::Instruments::Instrument.get(value)
      raise ArgumentError, "#{path}: unknown instrument #{value.inspect}" if instrument.nil?

      instrument
    end

    def player(value, players, path)
      return nil if value.nil?

      count = players.length
      return players[value] if value.is_a?(Integer) && value.between?(0, count - 1)

      raise ArgumentError, "#{path}: unknown player index #{value.inspect} (#{count} part players)"
    end

    # The from and to positions a ranged element must have.
    def ends(value, label, path)
      %w[from to].map do |key|
        position(value[key], "#{path}.#{key}") || raise(ArgumentError, "#{path}: a #{label} needs a #{key} position")
      end
    end

    private

    def bar_jump(value)
      return if value.nil?
      raise ArgumentError, "must be a Hash, got #{value.inspect}" unless value.is_a?(Hash)

      HeadMusic::Content::Jump.from_h(value)
    end

    def staff_system_values
      @staff_system_values ||= StaffSystemValues.new(self)
    end

    def voice_event_values
      @voice_event_values ||= VoiceEventValues.new
    end

    def timeline_values
      @timeline_values ||= TimelineValues.new(self)
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
      position = position(value["position"], path) || raise(ArgumentError, "#{path}: a dynamic event needs a position")
      raw_level = value["level"]
      level = catalog_value(raw_level, HeadMusic::Rudiment::Dynamic, path)
      raise ArgumentError, "#{path}: level must be a dynamic level, got #{raw_level.inspect}" unless level.level?

      [position, level]
    end

    def span(value, path)
      ensure_kind!(value, Hash, "span", path)
      kind = catalog_value(value["kind"], HeadMusic::Rudiment::SpanKind, "#{path}.kind")
      from_grace = boolean_value(value.fetch("from_grace", false), "#{path}.from_grace: ")

      [kind, *ends(value, "span", path), from_grace]
    end

    def tuplet(value, path)
      ensure_kind!(value, Hash, "tuplet", path)
      unit = value["unit"]
      [*ends(value, "tuplet", path), unit && rhythmic_value(unit, "#{path}.unit")]
    end
  end
end
