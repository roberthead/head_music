class HeadMusic::Content::Flow
  # Rebuilds a flow from a schema v4 hash.
  #
  # The order is the model's own dependency order: the timeline first, because
  # a position string rolls its counts and ticks over through the meter map;
  # then parts, with their instrument and staff-system changes, because a
  # voice's staff assignment names a staff of its part's system; then
  # placements; then repeat flags, which need their bar allocated; then
  # comments.
  class HashDeserializer < Deserializer
    SCHEMA_VERSION = HeadMusic::Content::Flow::SCHEMA_VERSION

    private

    # A v3 document names 20.1.0 rather than merely being rejected, because the
    # reader that understands it still ships and a caller needs to be told
    # where to find it.
    def unsupported_version_message(version)
      message = super
      message += "; read it with Flow.from_v3_h, which is retained in 21.x and removed in 22.0.0" if version == 3
      message
    end

    def timeline_hash
      @timeline_hash ||= hash["timeline"] || {}
    end

    def timeline_path(key)
      "timeline.#{key}"
    end

    def build(flow)
      apply_timeline_changes(flow)
      build_parts(flow)
      apply_repeat_flags(flow)
      add_comments(flow)
    end

    def apply_timeline_changes(flow)
      each_timeline_change("meter_changes") do |bar_number, change, path|
        flow.change_meter(bar_number, values.meter(change["meter"], path))
      end
      each_timeline_change("key_signature_changes") do |bar_number, change, path|
        tonal_context = values.tonal_context(change["tonal_context"], path)
        flow.change_key_signature(bar_number, values.fifths(change["signature"], path), tonal_context: tonal_context)
      end
      each_timeline_change("tempo_changes") do |bar_number, change, path|
        flow.change_tempo(bar_number, values.tempo(change["tempo"], path))
      end
    end

    def each_timeline_change(key, &block)
      each_change(timeline_hash[key], timeline_path(key), &block)
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
        apply_instrument_changes(part, part_hash, path)
        apply_staff_system_changes(part, part_hash, path)
        build_voices(part, part_hash, path)
      end
    end

    def apply_instrument_changes(part, part_hash, part_path)
      each_change(part_hash["instrument_changes"], "#{part_path}.instrument_changes") do |bar_number, change, path|
        part.change_instrument(bar_number, values.instrument(change["instrument"], path))
      end
    end

    def apply_staff_system_changes(part, part_hash, part_path)
      each_change(part_hash["staff_system_changes"], "#{part_path}.staff_system_changes") do |bar_number, change, path|
        staff_system = values.staff_system(change["staff_system"], path)
        raise ArgumentError, "#{path}: a staff system change names a staff system, got nil" if staff_system.nil?

        part.change_staff_system(bar_number, staff_system)
      end
    end

    def build_voices(part, part_hash, part_path)
      Array(part_hash["voices"]).each_with_index do |voice_hash, voice_index|
        voice = part.add_voice(role: voice_hash["role"])
        build_placements(voice, voice_hash, "#{part_path}.voices[#{voice_index}]")
        apply_staff_assignments(voice, part, voice_hash)
      end
    end

    # Assignments are replayed as bare map entries rather than through
    # #cross_to, because the serialized form is the map -- a span's two events
    # are already two entries, and reconstructing spans to re-derive them would
    # be inventing information the document does not carry.
    def apply_staff_assignments(voice, part, voice_hash)
      each_change(voice_hash["staff_assignments"], "staff_assignments") do |bar_number, assignment, _path|
        staff = part.staff_system_at(bar_number).staves[assignment["staff"].to_i]
        voice.assign_staff(bar_number, staff) if staff
      end
    end
  end
end
