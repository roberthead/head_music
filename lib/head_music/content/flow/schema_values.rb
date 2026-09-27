class HeadMusic::Content::Flow
  # Validates and coerces raw schema values into domain objects for the
  # HashDeserializer. Every method takes the raw value and the path it came
  # from, returning a validated object or raising ArgumentError with that path
  # context. Stateless: it holds no reference to the source hash, so the
  # deserializer stays responsible for *where* values come from and this class
  # for *what* a value is allowed to be.
  class SchemaValues
    KIND_NAMES = {Array => "an Array", Hash => "a Hash"}.freeze

    delegate :staff_system, :staff, to: :staff_system_values

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

    # "sounds" is an array of sound data, empty for a rest. A pitched sound
    # is a pitch string; an unpitched sound is a one-key
    # {"unpitched" => name_key} hash. A nil element is never a rest, so it
    # fails like any other unknown sound.
    def voice_event_sounds(voice_event_hash, path)
      each_element(voice_event_hash["sounds"], "sounds", path) do |value, element_path|
        sound(value, element_path)
      end
    end

    # "syllables" is an optional array of sung-text data, one entry per verse.
    # Each entry is a {"text" => ..., "verse" => ..., "hyphen_after" => ...}
    # hash; verse defaults to 1. Text must be a non-empty string, verse a
    # positive integer, and no two entries may share a verse (a voice event holds
    # at most one syllable per verse).
    def voice_event_syllables(voice_event_hash, path)
      values = voice_event_hash["syllables"]
      return [] if values.nil?

      seen_verses = []
      each_element(values, "syllables", path) do |value, element_path|
        syllable(value, seen_verses, element_path)
      end
    end

    # An optional list of catalog keys, such as a voice event's articulations,
    # each known and none repeated.
    def catalog_keys(values, catalog, label, path)
      return [] if values.nil?

      each_element(values, label, path) do |value, element_path, index|
        raise ArgumentError, "#{path}: duplicate #{label} #{value.inspect}" if values.index(value) != index

        catalog_value(value, catalog, element_path)
      end
    end

    def note_dynamic(value, path)
      return nil if value.nil?

      dynamic = catalog_value(value, HeadMusic::Rudiment::Dynamic, path)
      raise ArgumentError, "#{path}: note_dynamic must be an accent, got #{value.inspect}" unless dynamic.accent?

      dynamic
    end

    # An optional list of {"position" => ..., "level" => ...} hashes, answered
    # as [position, level] pairs.
    def dynamic_events(values, path)
      return [] if values.nil?

      each_element(values, "dynamic_events", path) do |value, element_path|
        dynamic_event(value, element_path)
      end
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

    # The rudiment getters raise on some garbage and answer a hollow object on
    # the rest, so a validator treats both the same way: as nil, then checks.
    def attempt
      yield
    rescue
      nil
    end

    # Answers the validated elements, each yielded with its path and index.
    def each_element(values, label, path)
      ensure_kind!(values, Array, label, path)
      values.each_with_index.map do |value, index|
        yield value, "#{path}.#{label}[#{index}]", index
      end
    end

    def ensure_kind!(value, kind, label, path)
      raise ArgumentError, "#{path}: #{label} must be #{KIND_NAMES[kind]}, got #{value.inspect}" unless value.is_a?(kind)
    end

    # KeySignature.get returns a hollow object (nil tonic_spelling) for
    # garbage rather than nil, so presence of the tonic is the real check.
    def known_key_signature(value, label, path)
      key_signature = attempt { HeadMusic::Rudiment::KeySignature.get(value) }
      raise ArgumentError, "#{path}: unknown #{label} #{value.inspect}" unless key_signature&.tonic_spelling

      key_signature
    end

    def non_empty_string?(value)
      value.is_a?(String) && !value.empty?
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

    # A value that fails to parse would otherwise silently deserialize as
    # a rest.
    def pitch(value, path)
      pitch = HeadMusic::Rudiment::Pitch.get(value)
      raise ArgumentError, "#{path}: unknown pitch #{value.inspect}" unless pitch

      pitch
    end

    def syllable(value, seen_verses, path)
      ensure_kind!(value, Hash, "syllable", path)
      text = value["text"]
      unless non_empty_string?(text)
        raise ArgumentError, "#{path}: syllable text must be a non-empty String, got #{text.inspect}"
      end

      verse = value.fetch("verse", 1)
      unless verse.is_a?(Integer) && verse.positive?
        raise ArgumentError, "#{path}: verse must be a positive Integer, got #{verse.inspect}"
      end

      raise ArgumentError, "#{path}: duplicate verse #{verse}" if seen_verses.include?(verse)
      seen_verses << verse

      HeadMusic::Content::Syllable.from_h(value)
    end

    def catalog_value(value, catalog, path)
      entry = catalog.get(value) if value.is_a?(String)
      raise ArgumentError, "#{path}: unknown #{catalog.name.demodulize.downcase} #{value.inspect}" unless entry

      entry
    end

    def dynamic_event(value, path)
      ensure_kind!(value, Hash, "dynamic event", path)
      position = position(value["position"], path)
      raise ArgumentError, "#{path}: a dynamic event needs a position" if position.nil?

      level = catalog_value(value["level"], HeadMusic::Rudiment::Dynamic, path)
      raise ArgumentError, "#{path}: level must be a dynamic level, got #{value["level"].inspect}" unless level.level?

      [position, level]
    end

    def sound(value, path)
      return pitch(value, path) if value.is_a?(String)
      return unpitched_sound(value, path) if value.is_a?(Hash)

      raise ArgumentError, "#{path}: unknown sound #{value.inspect}"
    end

    # A nil name_key is the generic unpitched sound. A pitched instrument is
    # a valid hit surface (a knock on a violin body is unpitched), so any
    # catalog name or alias resolves.
    def unpitched_sound(value, path)
      unless value.keys == ["unpitched"]
        raise ArgumentError, "#{path}: unknown sound #{value.inspect}"
      end

      name = value["unpitched"]
      valid_name = name.nil? || non_empty_string?(name)
      sound = HeadMusic::Rudiment::UnpitchedSound.get(name) if valid_name
      raise ArgumentError, "#{path}: unknown instrument #{name.inspect}" unless sound

      sound
    end
  end
end
