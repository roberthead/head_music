class HeadMusic::Content::Flow
  # Rebuilds a flow from a schema v4 hash by replaying the public builder API.
  #
  # The order is the model's own dependency order: the timeline first, because
  # a position string rolls its counts and ticks over through the meter map;
  # then parts, with their instrument and staff-system changes, because a
  # voice's staff assignment names a staff of its part's system; then
  # placements; then repeat flags, which need their bar allocated; then
  # comments.
  #
  # Raw values are validated at the boundary by SchemaValues, whose validators
  # are container-agnostic and so are reused wholesale from v3 -- only the walk
  # over the containers is new.
  class HashDeserializer
    def initialize(hash)
      raise ArgumentError, "expected a Hash, got #{hash.class}" unless hash.is_a?(Hash)

      @hash = hash.deep_transform_keys(&:to_s)
      validate_schema_version
    end

    def flow
      @flow ||= build_base_flow.tap do |flow|
        apply_timeline_changes(flow)
        build_parts(flow)
        apply_repeat_flags(flow)
        add_comments(flow)
      end
    end

    private

    attr_reader :hash

    def values
      @values ||= SchemaValues.new
    end

    # A v3 document names 20.1.0 rather than merely being rejected, because the
    # reader that understands it still ships and a caller needs to be told
    # where to find it.
    def validate_schema_version
      version = hash["schema_version"]
      return if version.is_a?(Integer) && version == HeadMusic::Content::Flow::SCHEMA_VERSION

      message = "unsupported schema_version: #{version.inspect} (supported: #{HeadMusic::Content::Flow::SCHEMA_VERSION})"
      message += "; read it with Flow.from_v3_h, which is retained in 21.x and removed in 22.0.0" if version == 3
      raise ArgumentError, message
    end

    def timeline_hash
      @timeline_hash ||= hash["timeline"] || {}
    end

    def build_base_flow
      HeadMusic::Content::Flow.new(
        name: hash["name"],
        key_signature: values.key_signature(timeline_hash["key_signature"], "timeline.key_signature"),
        meter: values.meter(timeline_hash["meter"], "timeline.meter"),
        tempo: values.tempo(timeline_hash["tempo"], "timeline.tempo"),
        composer: hash["composer"],
        origin: hash["origin"]
      )
    end

    def apply_timeline_changes(flow)
      Array(timeline_hash["meter_changes"]).each_with_index do |change, index|
        path = "timeline.meter_changes[#{index}]"
        flow.change_meter(values.bar_number(change, index, "timeline.meter_changes"), values.meter(change["meter"], path))
      end
      Array(timeline_hash["key_signature_changes"]).each_with_index do |change, index|
        path = "timeline.key_signature_changes[#{index}]"
        flow.change_key_signature(
          values.bar_number(change, index, "timeline.key_signature_changes"),
          values.fifths(change["signature"], path),
          tonal_context: values.tonal_context(change["tonal_context"], path)
        )
      end
      Array(timeline_hash["tempo_changes"]).each_with_index do |change, index|
        path = "timeline.tempo_changes[#{index}]"
        flow.change_tempo(values.bar_number(change, index, "timeline.tempo_changes"), values.tempo(change["tempo"], path))
      end
    end

    # Staff system changes replay before the voices because a voice's staff
    # assignment is resolved against the system in force at its bar.
    def build_parts(flow)
      Array(hash["parts"]).each_with_index do |part_hash, part_index|
        path = "parts[#{part_index}]"
        part = flow.add_part(
          instrument: values.instrument(part_hash["instrument"], path),
          staff_system: values.staff_system(part_hash["staff_system"], path)
        )
        apply_instrument_changes(part, part_hash, part_index)
        apply_staff_system_changes(part, part_hash, part_index)
        build_voices(part, part_hash, part_index)
      end
    end

    def apply_staff_system_changes(part, part_hash, part_index)
      Array(part_hash["staff_system_changes"]).each_with_index do |change, index|
        base = "parts[#{part_index}].staff_system_changes"
        staff_system = values.staff_system(change["staff_system"], "#{base}[#{index}]")
        raise ArgumentError, "#{base}[#{index}]: a staff system change names a staff system, got nil" if staff_system.nil?

        part.change_staff_system(values.bar_number(change, index, base), staff_system)
      end
    end

    def apply_instrument_changes(part, part_hash, part_index)
      Array(part_hash["instrument_changes"]).each_with_index do |change, index|
        base = "parts[#{part_index}].instrument_changes"
        part.change_instrument(
          values.bar_number(change, index, base),
          values.instrument(change["instrument"], "#{base}[#{index}]")
        )
      end
    end

    def build_voices(part, part_hash, part_index)
      Array(part_hash["voices"]).each_with_index do |voice_hash, voice_index|
        voice = part.add_voice(role: voice_hash["role"])
        build_placements(voice, voice_hash, "parts[#{part_index}].voices[#{voice_index}]")
        apply_staff_assignments(voice, part, voice_hash)
      end
    end

    def build_placements(voice, voice_hash, voice_path)
      Array(voice_hash["placements"]).each_with_index do |placement_hash, placement_index|
        path = "#{voice_path}.placements[#{placement_index}]"
        placement = voice.place(
          values.position(placement_hash["position"], path),
          values.rhythmic_value(placement_hash["rhythmic_value"], path),
          values.placement_sounds(placement_hash, path)
        )
        placement.beam_break_before = placement_hash["beam_break_before"] if placement_hash.key?("beam_break_before")
        values.placement_syllables(placement_hash, path).each do |syllable|
          placement.sing(syllable.text, verse: syllable.verse, hyphen_after: syllable.hyphen_after)
        end
      end
    end

    # Assignments are replayed as bare map entries rather than through
    # #cross_to, because the serialized form is the map -- a span's two events
    # are already two entries, and reconstructing spans to re-derive them would
    # be inventing information the document does not carry.
    def apply_staff_assignments(voice, part, voice_hash)
      Array(voice_hash["staff_assignments"]).each_with_index do |assignment, index|
        bar_number = values.bar_number(assignment, index, "staff_assignments")
        staff = part.staff_system_at(bar_number).staves[assignment["staff"].to_i]
        voice.assign_staff(bar_number, staff) if staff
      end
    end

    def bar_hashes
      @bar_hashes ||= Array(hash["bars"])
    end

    def apply_repeat_flags(flow)
      bar_hashes.each_with_index do |bar_hash, index|
        bar = flow.bars(values.bar_number(bar_hash, index)).last
        bar.starts_repeat = true if bar_hash["starts_repeat"]
        ends_repeat = bar_hash["ends_repeat_after_num_plays"]
        bar.ends_repeat_after_num_plays = ends_repeat if ends_repeat
        plays_on_passes = bar_hash["plays_on_passes"]
        bar.plays_on_passes = plays_on_passes if plays_on_passes
      end
    end

    def add_comments(flow)
      Array(hash["comments"]).each_with_index do |comment_hash, index|
        raw_position = comment_hash["position"]
        position = values.position(raw_position, "comments[#{index}]") if raw_position
        flow.add_comment(comment_hash["text"], position)
      end
    end
  end
end
