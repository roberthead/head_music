class HeadMusic::Content::Flow
  # Rebuilds a flow from a **schema v3** hash, in which the opening meter and
  # key live at the top level, changes hang off the bars, and voices have no
  # part above them.
  #
  # Retained read-only so that an application holding persisted v3 documents
  # can migrate them by reading and re-saving, rather than by loading two gem
  # versions at once. The earlier schema bumps shipped a migration recipe
  # instead -- v2 to v3 was "rename each placement's pitches key to sounds",
  # doable in SQL against a jsonb column -- but v3 to v4 restructures the
  # container, so no equivalent recipe can be written.
  #
  # Every concept it replays has a home in the new model: a v3 voice becomes a
  # part holding one voice, which is what Flow#add_voice already mints.
  #
  # Deleted in 22.0.0.
  class V3HashDeserializer < Deserializer
    SCHEMA_VERSION = 3

    private

    def timeline_hash
      hash
    end

    def timeline_path(key)
      key
    end

    def build(flow)
      apply_bar_changes(flow)
      build_voices(flow)
      apply_repeat_flags(flow)
      add_comments(flow)
    end

    def apply_bar_changes(flow)
      each_change(bar_hashes, "bars") do |bar_number, bar_hash, path|
        key_signature = values.key_signature(bar_hash["key_signature"], path)
        meter = values.meter(bar_hash["meter"], path)
        flow.change_key_signature(bar_number, key_signature) if key_signature
        flow.change_meter(bar_number, meter) if meter
      end
    end

    def build_voices(flow)
      Array(hash["voices"]).each_with_index do |voice_hash, voice_index|
        build_placements(flow.add_voice(role: voice_hash["role"]), voice_hash, "voices[#{voice_index}]")
      end
    end
  end
end
