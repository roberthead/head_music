class HeadMusic::Content::Flow
  # Rebuilds a flow from a schema v4 hash, in dependency order: the timeline
  # first, because a position string rolls its counts and ticks over through the
  # meter map; then parts, because a voice's staff assignment names a staff of
  # its part's system; then placements; then repeat flags, which need their bar
  # allocated.
  class HashDeserializer < Deserializer
    SCHEMA_VERSION = HeadMusic::Content::Flow::SCHEMA_VERSION

    private

    # No recipe migrates v3 in place, so a v3 document is told which release
    # still reads it rather than merely rejected.
    def unsupported_version_message(version)
      message = super
      message += "; read it with Flow.from_v3_h in head_music 21.x and save it again" if version == 3
      message
    end

    def timeline_hash
      @timeline_hash ||= hash["timeline"] || {}
    end

    def timeline_path(key)
      "timeline.#{key}"
    end

    def build(flow)
      apply_citations(flow)
      apply_timeline_changes(flow)
      build_parts(flow)
      apply_repeat_flags(flow)
      add_comments(flow)
    end

    # Read here rather than on the shared base, so the v3 reader gains nothing.
    # A document written before these keys existed has neither, and reads.
    def apply_citations(flow)
      work = hash["work"]
      flow.work = HeadMusic::Content::Work.from_h(work) if work
      source = hash["source"]
      flow.source = publication_from_h(source) if source
    end

    # A source written from the cantus firmus catalog carries its key, and
    # reads back as the catalog entry itself rather than as a copy of its fields.
    def publication_from_h(source_hash)
      key = source_hash["key"]
      (key && HeadMusic::Content::CantusFirmus::Source.get(key)) || HeadMusic::Content::Publication.from_h(source_hash)
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

    # Replayed as bare map entries: a crossing is one event, and the serialized
    # form is the map.
    def apply_staff_assignments(voice, part, voice_hash)
      each_change(voice_hash["staff_assignments"], "staff_assignments") do |bar_number, assignment, _path|
        staff = part.staff_system_at(bar_number).staves[assignment["staff"].to_i]
        voice.assign_staff(bar_number, staff) if staff
      end
    end
  end
end
