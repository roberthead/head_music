class HeadMusic::Content::Flow
  # What every schema version's reader does the same way: check the version,
  # build the base flow, and replay voice events, bar fields, and comments
  # through the public builder API. A subclass names its SCHEMA_VERSION, says
  # where the opening timeline values live, and walks its own containers.
  #
  # Raw values are validated at the boundary by SchemaValues, so corrupted
  # input raises ArgumentError with path context instead of silently
  # deserializing wrong.
  class Deserializer
    # A document's keys are read as strings, however it was written.
    def self.document(hash)
      raise ArgumentError, "expected a Hash, got #{hash.class}" unless hash.is_a?(Hash)

      hash.deep_transform_keys(&:to_s)
    end

    def initialize(hash)
      @hash = Deserializer.document(hash)
      validate_schema_version
    end

    def flow
      @flow ||= build_base_flow.tap { |flow| build(flow) }
    end

    private

    attr_reader :hash

    def values
      @values ||= SchemaValues.new
    end

    def validate_schema_version
      version = hash["schema_version"]
      return if version.is_a?(Integer) && version == self.class::SCHEMA_VERSION

      raise ArgumentError, unsupported_version_message(version)
    end

    def unsupported_version_message(version)
      "unsupported schema_version: #{version.inspect} (supported: #{self.class::SCHEMA_VERSION})"
    end

    def build_base_flow
      HeadMusic::Content::Flow.new(
        name: hash["name"],
        key_signature: opening_value(:key_signature),
        meter: opening_value(:meter),
        tempo: opening_value(:tempo),
        composer: hash["composer"],
        origin: hash["origin"]
      )
    end

    # Each opening timeline value is validated by the SchemaValues method of
    # the same name.
    def opening_value(key)
      values.public_send(key, timeline_hash[key.to_s], timeline_path(key))
    end

    def bar_hashes
      @bar_hashes ||= Array(hash["bars"])
    end

    # A list of bar-keyed changes, each yielded with its validated bar number
    # and its path for error messages.
    def each_change(list, base)
      Array(list).each_with_index do |change, index|
        yield values.bar_number(change, index, base), change, "#{base}[#{index}]"
      end
    end

    def build_voice_events(voice, voice_hash, voice_path)
      Array(voice_hash["voice_events"]).each_with_index do |voice_event_hash, index|
        build_voice_event(voice, voice_event_hash, "#{voice_path}.voice_events[#{index}]")
      end
    end

    def build_voice_event(voice, voice_event_hash, path)
      voice_event = voice.place(
        values.position(voice_event_hash["position"], path),
        values.rhythmic_value(voice_event_hash["rhythmic_value"], path),
        values.voice_event_sounds(voice_event_hash, path)
      )
      voice_event.beam_break_before = voice_event_hash["beam_break_before"] if voice_event_hash.key?("beam_break_before")
      sing_syllables(voice_event, voice_event_hash, path)
      apply_markings(voice_event, voice_event_hash, path)
      add_grace_notes(voice_event, voice_event_hash, path)
    end

    def sing_syllables(voice_event, voice_event_hash, path)
      syllables = values.voice_event_syllables(voice_event_hash, path)
      return if syllables.empty?

      reject_rest(voice_event, "syllables", path)
      syllables.each do |syllable|
        voice_event.sing(syllable.text, verse: syllable.verse, hyphen_after: syllable.hyphen_after)
      end
    end

    # A rest would refuse these itself, but without the document path.
    def reject_rest(voice_event, carried, path)
      raise ArgumentError, "#{path}: a rest cannot carry #{carried}" if voice_event.rest?
    end

    def add_grace_notes(voice_event, voice_event_hash, path)
      grace_notes = values.grace_notes(voice_event_hash["grace_notes"], path)
      return if grace_notes.empty?

      reject_rest(voice_event, "grace notes", path)

      each_placed(grace_notes, "grace_notes", path) do |sounds, rhythmic_value, options|
        voice_event.add_grace_note(sounds, rhythmic_value, **options)
      end
    end

    # Added after the voice events they bracket.
    def add_tuplets(voice, voice_hash, path)
      each_placed(values.tuplets(voice_hash["tuplets"], path), "tuplets", path) do |from, to, unit|
        voice.group_tuplet(from: from, to: to, unit: unit)
      end
    end

    def apply_markings(voice_event, voice_event_hash, path)
      articulations = values.catalog_keys(voice_event_hash["articulations"], HeadMusic::Rudiment::Articulation, "articulations", path)
      ornaments = values.catalog_keys(voice_event_hash["ornaments"], HeadMusic::Rudiment::Ornament, "ornaments", path)
      note_dynamic = values.note_dynamic(voice_event_hash["note_dynamic"], "#{path}.note_dynamic")
      return if articulations.empty? && ornaments.empty? && note_dynamic.nil?
      reject_rest(voice_event, "articulations, ornaments, or a note dynamic", path)

      voice_event.articulate(*articulations).embellish(*ornaments)
      voice_event.note_dynamic = note_dynamic
    end

    def place_dynamic_events(target, container_hash, path)
      each_placed(values.dynamic_events(container_hash["dynamic_events"], path), "dynamic_events", path) do |position, level|
        target.place_dynamic(position, level)
      end
    end

    # Added after the voice events, whose positions a span's ends must find.
    def add_spans(target, container_hash, path)
      each_placed(values.spans(container_hash["spans"], path), "spans", path) do |kind, from, to, from_grace|
        target.add_span(kind, from: from, to: to, from_grace: from_grace)
      end
    end

    # Each item is placed through the public API, so a mistake such as a
    # duplicate position raises as it would for a caller, but with the
    # document path.
    def each_placed(items, label, path)
      items.each_with_index do |item, index|
        yield(*item)
      rescue ArgumentError => error
        raise ArgumentError, "#{path}.#{label}[#{index}]: #{error.message}"
      end
    end

    def apply_bar_fields(flow)
      each_change(bar_hashes, "bars") do |bar_number, bar_hash, path|
        bar = flow.bars(bar_number).last
        bar_hash.slice(*SchemaValues::BAR_FIELDS).each do |field, value|
          bar.public_send(:"#{field}=", values.bar_field(field, value))
        rescue ArgumentError => error
          raise ArgumentError, "#{path}.#{field}: #{error.message}"
        end
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
