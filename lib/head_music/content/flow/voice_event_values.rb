class HeadMusic::Content::Flow
  # The voice-event corner of SchemaValues: a voice event's sounds, sung
  # syllables, and markings. Split from the scalar validators, as
  # StaffSystemValues was, because the two together outgrew one class.
  class VoiceEventValues
    include SchemaValidation

    # A held note of a melisma, read from "syllables" and applied after the
    # voice's events, since it needs the event before it.
    Extender = Data.define(:verse)

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
    # hash, or an extender {"extend" => true, "verse" => ...}; verse defaults
    # to 1. Text must be a non-empty string, verse a positive integer, and no
    # two entries may share a verse (a voice event holds a syllable or an
    # extender per verse).
    def voice_event_syllables(voice_event_hash, path)
      values = voice_event_hash["syllables"]
      return [] if values.nil?

      seen_verses = []
      each_element(values, "syllables", path) do |value, element_path|
        syllable(value, seen_verses, element_path)
      end
    end

    # An optional list of catalog keys, such as a voice event's articulations,
    # each known and none repeated, even through an alias or another spelling.
    def catalog_keys(values, catalog, label, path)
      return [] if values.nil?

      seen = []
      each_element(values, label, path) do |value, element_path|
        entry = catalog_value(value, catalog, element_path)
        raise ArgumentError, "#{path}: duplicate #{label} #{value.inspect}" if seen.include?(entry)

        seen << entry
        entry
      end
    end

    # An optional list of {"sounds", "rhythmic_value", "slashed"?, "tied"?,
    # "articulations"?} hashes, each answered as the arguments of
    # NoteEvent#add_grace_note: [sounds, rhythmic_value, options].
    def grace_notes(values, path)
      return [] if values.nil?

      each_element(values, "grace_notes", path) { |value, element_path| grace_note(value, element_path) }
    end

    def note_dynamic(value, path)
      return nil if value.nil?

      dynamic = catalog_value(value, HeadMusic::Rudiment::Dynamic, path)
      raise ArgumentError, "#{path}: note_dynamic must be an accent, got #{value.inspect}" unless dynamic.accent?

      dynamic
    end

    private

    # A value that fails to parse would otherwise silently deserialize as
    # a rest.
    def pitch(value, path)
      pitch = HeadMusic::Rudiment::Pitch.get(value)
      raise ArgumentError, "#{path}: unknown pitch #{value.inspect}" unless pitch

      pitch
    end

    def grace_note(value, path)
      ensure_kind!(value, Hash, "grace note", path)
      sounds = each_element(value["sounds"], "sounds", path) { |sound_value, element_path| sound(sound_value, element_path) }
      options = {
        slashed: flag(value, "slashed", path),
        tied: flag(value, "tied", path),
        articulations: catalog_keys(value["articulations"], HeadMusic::Rudiment::Articulation, "articulations", path)
      }
      [sounds, grace_value(value["rhythmic_value"], path), options]
    end

    def grace_value(value, path)
      rhythmic_value = HeadMusic::Rudiment::RhythmicValue.get(value) if value.is_a?(String)
      raise ArgumentError, "#{path}: unknown rhythmic value #{value.inspect}" unless rhythmic_value&.unit

      rhythmic_value
    end

    def flag(value, key, path)
      flag = value.fetch(key, false)
      raise ArgumentError, "#{path}.#{key}: must be true or false, got #{flag.inspect}" unless [true, false].include?(flag)

      flag
    end

    def syllable(value, seen_verses, path)
      ensure_kind!(value, Hash, "syllable", path)
      verse = syllable_verse(value, seen_verses, path)
      return extender(value, verse, path) if value.key?("extend")

      text = value["text"]
      unless non_empty_string?(text)
        raise ArgumentError, "#{path}: syllable text must be a non-empty String, got #{text.inspect}"
      end

      HeadMusic::Content::Syllable.from_h(value)
    end

    def syllable_verse(value, seen_verses, path)
      verse = value.fetch("verse", 1)
      unless verse.is_a?(Integer) && verse.positive?
        raise ArgumentError, "#{path}: verse must be a positive Integer, got #{verse.inspect}"
      end

      raise ArgumentError, "#{path}: duplicate verse #{verse}" if seen_verses.include?(verse)
      seen_verses << verse
      verse
    end

    def extender(value, verse, path)
      raise ArgumentError, "#{path}.extend: must be true, got #{value["extend"].inspect}" unless value["extend"] == true

      sung = value.keys & %w[text hyphen_after]
      raise ArgumentError, "#{path}: an extender carries no #{sung.join(" or ")}" if sung.any?

      Extender.new(verse)
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
