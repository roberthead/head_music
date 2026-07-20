class HeadMusic::Content::Composition
  # Rebuilds a composition from a schema v3 hash by replaying the public
  # builder API in dependency order: meter and key changes first (position
  # strings roll counts and ticks over via the meter map), then placements,
  # then repeat flags (a pickup-bar flag needs its bar allocated), then
  # comments. Raw values are validated at the boundary by SchemaValues so
  # corrupted input raises ArgumentError with path context instead of
  # silently deserializing wrong.
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

    def values
      @values ||= SchemaValues.new
    end

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
        key_signature: values.key_signature(hash["key_signature"], "key_signature"),
        meter: values.meter(hash["meter"], "meter"),
        composer: hash["composer"],
        origin: hash["origin"]
      )
    end

    def bar_hashes
      @bar_hashes ||= Array(hash["bars"])
    end

    def apply_bar_changes(composition)
      bar_hashes.each_with_index do |bar_hash, index|
        number = values.bar_number(bar_hash, index)
        path = "bars[#{index}]"
        key_signature = values.key_signature(bar_hash["key_signature"], path)
        meter = values.meter(bar_hash["meter"], path)
        composition.change_key_signature(number, key_signature) if key_signature
        composition.change_meter(number, meter) if meter
      end
    end

    def build_voices(composition)
      Array(hash["voices"]).each_with_index do |voice_hash, voice_index|
        voice = composition.add_voice(role: voice_hash["role"])
        Array(voice_hash["placements"]).each_with_index do |placement_hash, placement_index|
          path = "voices[#{voice_index}].placements[#{placement_index}]"
          position = values.position(placement_hash["position"], path)
          rhythmic_value = values.rhythmic_value(placement_hash["rhythmic_value"], path)
          sounds = values.placement_sounds(placement_hash, path)
          placement = voice.place(position, rhythmic_value, sounds)
          placement.beam_break_before = placement_hash["beam_break_before"] if placement_hash.key?("beam_break_before")
        end
      end
    end

    def apply_repeat_flags(composition)
      bar_hashes.each_with_index do |bar_hash, index|
        next unless repeat_state?(bar_hash)

        bar = composition.bars(values.bar_number(bar_hash, index)).last
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
        position = values.position(raw_position, "comments[#{index}]") if raw_position
        composition.add_comment(comment_hash["text"], position)
      end
    end

    def repeat_state?(bar_hash)
      bar_hash["starts_repeat"] || bar_hash["ends_repeat_after_num_plays"] || bar_hash["plays_on_passes"]
    end
  end
end
