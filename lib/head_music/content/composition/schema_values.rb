class HeadMusic::Content::Composition
  # Validates and coerces raw schema values into domain objects for the
  # HashDeserializer. Every method takes the raw value and the path it came
  # from, returning a validated object or raising ArgumentError with that path
  # context. Stateless: it holds no reference to the source hash, so the
  # deserializer stays responsible for *where* values come from and this class
  # for *what* a value is allowed to be.
  class SchemaValues
    # Position silently coerces garbage strings to "0:1:000", which would
    # mislocate content with no error, so the shape is validated up front.
    # Accepts "bar", "bar:count", or "bar:count:tick" with non-negative parts.
    def position(value, path)
      return nil if value.nil?

      unless value.is_a?(String) && value.match?(/\A\d+(:\d+){0,2}\z/)
        raise ArgumentError, "#{path}: unknown position #{value.inspect}"
      end
      value
    end

    # KeySignature.get returns a hollow object (nil tonic_spelling) for
    # garbage rather than nil, so presence of the tonic is the real check.
    def key_signature(value, path)
      return nil if value.nil?

      key_signature = begin
        HeadMusic::Rudiment::KeySignature.get(value)
      rescue
        nil
      end
      unless key_signature&.tonic_spelling
        raise ArgumentError, "#{path}: unknown key signature #{value.inspect}"
      end
      key_signature
    end

    def meter(value, path)
      return nil if value.nil?

      meter = begin
        HeadMusic::Rudiment::Meter.get(value)
      rescue
        nil
      end
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

    # "sounds" is an array of sound data, empty for a rest. A pitched sound
    # is a pitch string; an unpitched sound is a one-key
    # {"unpitched" => name_key} hash. A nil element is never a rest, so it
    # fails like any other unknown sound.
    def placement_sounds(placement_hash, path)
      values = placement_hash["sounds"]
      unless values.is_a?(Array)
        raise ArgumentError, "#{path}: sounds must be an Array, got #{values.inspect}"
      end

      values.each_with_index.map do |value, index|
        sound(value, "#{path}.sounds[#{index}]")
      end
    end

    # "syllables" is an optional array of sung-text data, one entry per verse.
    # Each entry is a {"text" => ..., "verse" => ..., "hyphen_after" => ...}
    # hash; verse defaults to 1. Text must be a non-empty string, verse a
    # positive integer, and no two entries may share a verse (a placement holds
    # at most one syllable per verse).
    def placement_syllables(placement_hash, path)
      values = placement_hash["syllables"]
      return [] if values.nil?

      unless values.is_a?(Array)
        raise ArgumentError, "#{path}: syllables must be an Array, got #{values.inspect}"
      end

      seen_verses = []
      values.each_with_index.map do |value, index|
        syllable(value, seen_verses, "#{path}.syllables[#{index}]")
      end
    end

    def bar_number(bar_hash, index)
      number = bar_hash["number"]
      unless number.is_a?(Integer) && number >= 0
        raise ArgumentError, "bars[#{index}]: bar number must be an Integer of at least 0, got #{number.inspect}"
      end
      number
    end

    private

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
      unless value.is_a?(Hash)
        raise ArgumentError, "#{path}: syllable must be a Hash, got #{value.inspect}"
      end

      text = value["text"]
      unless text.is_a?(String) && !text.empty?
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
      valid_name = name.nil? || (name.is_a?(String) && !name.empty?)
      sound = HeadMusic::Rudiment::UnpitchedSound.get(name) if valid_name
      raise ArgumentError, "#{path}: unknown instrument #{name.inspect}" unless sound

      sound
    end
  end
end
