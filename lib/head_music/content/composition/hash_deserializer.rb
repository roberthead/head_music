class HeadMusic::Content::Composition
  # Rebuilds a composition from a schema v3 hash by replaying the public
  # builder API in dependency order: meter and key changes first (position
  # strings roll counts and ticks over via the meter map), then placements,
  # then repeat flags (a pickup-bar flag needs its bar allocated), then
  # comments. Validates values at the boundary so corrupted input raises
  # ArgumentError with path context instead of silently deserializing wrong.
  class HashDeserializer
    def initialize(hash)
      raise ArgumentError, "expected a Hash, got #{hash.class}" unless hash.is_a?(Hash)

      @hash = hash.deep_transform_keys(&:to_s)
      validate_schema_version
    end

    def composition
      @composition ||= build_base_composition.tap do |composition|
        apply_bar_changes(composition)
        build_voices(composition)
        apply_repeat_flags(composition)
        add_comments(composition)
      end
    end

    private

    attr_reader :hash

    def validate_schema_version
      version = hash["schema_version"]
      return if version.is_a?(Integer) && version == SCHEMA_VERSION

      message = "unsupported schema_version: #{version.inspect} (supported: #{SCHEMA_VERSION})"
      if version == 2
        message += "; migrate v2 \"pitches\" arrays to v3 \"sounds\" arrays " \
          "(pitch strings unchanged; unpitched sounds are {\"unpitched\" => name_key} objects)"
      end
      raise ArgumentError, message
    end

    def build_base_composition
      HeadMusic::Content::Composition.new(
        name: hash["name"],
        key_signature: parsed_key_signature(hash["key_signature"], "key_signature"),
        meter: parsed_meter(hash["meter"], "meter"),
        composer: hash["composer"],
        origin: hash["origin"]
      )
    end

    def bar_hashes
      @bar_hashes ||= Array(hash["bars"])
    end

    def apply_bar_changes(composition)
      bar_hashes.each_with_index do |bar_hash, index|
        number = validated_bar_number(bar_hash, index)
        path = "bars[#{index}]"
        key_signature = parsed_key_signature(bar_hash["key_signature"], path)
        meter = parsed_meter(bar_hash["meter"], path)
        composition.change_key_signature(number, key_signature) if key_signature
        composition.change_meter(number, meter) if meter
      end
    end

    def build_voices(composition)
      Array(hash["voices"]).each_with_index do |voice_hash, voice_index|
        voice = composition.add_voice(role: voice_hash["role"])
        Array(voice_hash["placements"]).each_with_index do |placement_hash, placement_index|
          path = "voices[#{voice_index}].placements[#{placement_index}]"
          position = parsed_position(placement_hash["position"], path)
          rhythmic_value = parsed_rhythmic_value(placement_hash["rhythmic_value"], path)
          sounds = parsed_placement_sounds(placement_hash, path)
          placement = voice.place(position, rhythmic_value, sounds)
          placement.beam_break_before = placement_hash["beam_break_before"] if placement_hash.key?("beam_break_before")
        end
      end
    end

    def apply_repeat_flags(composition)
      bar_hashes.each_with_index do |bar_hash, index|
        next unless repeat_state?(bar_hash)

        bar = composition.bars(validated_bar_number(bar_hash, index)).last
        bar.starts_repeat = true if bar_hash["starts_repeat"]
        ends_repeat = bar_hash["ends_repeat_after_num_plays"]
        bar.ends_repeat_after_num_plays = ends_repeat if ends_repeat
        plays_on_passes = bar_hash["plays_on_passes"]
        bar.plays_on_passes = plays_on_passes if plays_on_passes
      end
    end

    def add_comments(composition)
      Array(hash["comments"]).each_with_index do |comment_hash, index|
        raw_position = comment_hash["position"]
        position = parsed_position(raw_position, "comments[#{index}]") if raw_position
        composition.add_comment(comment_hash["text"], position)
      end
    end

    def repeat_state?(bar_hash)
      bar_hash["starts_repeat"] || bar_hash["ends_repeat_after_num_plays"] || bar_hash["plays_on_passes"]
    end

    def validated_bar_number(bar_hash, index)
      number = bar_hash["number"]
      unless number.is_a?(Integer) && number >= 0
        raise ArgumentError, "bars[#{index}]: bar number must be an Integer of at least 0, got #{number.inspect}"
      end
      number
    end

    # Position silently coerces garbage strings to "0:1:000", which would
    # mislocate content with no error, so the shape is validated up front.
    # Accepts "bar", "bar:count", or "bar:count:tick" with non-negative parts.
    def parsed_position(value, path)
      return nil if value.nil?

      unless value.is_a?(String) && value.match?(/\A\d+(:\d+){0,2}\z/)
        raise ArgumentError, "#{path}: unknown position #{value.inspect}"
      end
      value
    end

    # KeySignature.get returns a hollow object (nil tonic_spelling) for
    # garbage rather than nil, so presence of the tonic is the real check.
    def parsed_key_signature(value, path)
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

    def parsed_meter(value, path)
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

    def parsed_rhythmic_value(value, path)
      rhythmic_value = HeadMusic::Rudiment::RhythmicValue.get(value)
      unless valid_rhythmic_value?(rhythmic_value)
        raise ArgumentError, "#{path}: unknown rhythmic value #{value.inspect}"
      end
      rhythmic_value
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
    def parsed_pitch(value, path)
      pitch = HeadMusic::Rudiment::Pitch.get(value)
      raise ArgumentError, "#{path}: unknown pitch #{value.inspect}" unless pitch

      pitch
    end

    # "sounds" is an array of sound data, empty for a rest. A pitched sound
    # is a pitch string; an unpitched sound is a one-key
    # {"unpitched" => name_key} hash. A nil element is never a rest, so it
    # fails like any other unknown sound.
    def parsed_placement_sounds(placement_hash, path)
      values = placement_hash["sounds"]
      unless values.is_a?(Array)
        raise ArgumentError, "#{path}: sounds must be an Array, got #{values.inspect}"
      end

      values.each_with_index.map do |value, index|
        parsed_sound(value, "#{path}.sounds[#{index}]")
      end
    end

    def parsed_sound(value, path)
      return parsed_pitch(value, path) if value.is_a?(String)
      return parsed_unpitched_sound(value, path) if value.is_a?(Hash)

      raise ArgumentError, "#{path}: unknown sound #{value.inspect}"
    end

    # A nil name_key is the generic unpitched sound. A pitched instrument is
    # a valid hit surface (a knock on a violin body is unpitched), so any
    # catalog name or alias resolves.
    def parsed_unpitched_sound(value, path)
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
