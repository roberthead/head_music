class HeadMusic::Content::Flow
  # What every schema version's reader does the same way: check the version,
  # build the base flow, and replay voice events, repeat flags, and comments
  # through the public builder API. A subclass names its SCHEMA_VERSION, says
  # where the opening timeline values live, and walks its own containers.
  #
  # Raw values are validated at the boundary by SchemaValues, so corrupted
  # input raises ArgumentError with path context instead of silently
  # deserializing wrong.
  class Deserializer
    def initialize(hash)
      raise ArgumentError, "expected a Hash, got #{hash.class}" unless hash.is_a?(Hash)

      @hash = hash.deep_transform_keys(&:to_s)
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
        key_signature: values.key_signature(timeline_hash["key_signature"], timeline_path("key_signature")),
        meter: values.meter(timeline_hash["meter"], timeline_path("meter")),
        tempo: values.tempo(timeline_hash["tempo"], timeline_path("tempo")),
        composer: hash["composer"],
        origin: hash["origin"]
      )
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
      Array(voice_hash["voice_events"]).each_with_index do |voice_event_hash, voice_event_index|
        path = "#{voice_path}.voice_events[#{voice_event_index}]"
        voice_event = voice.place(
          values.position(voice_event_hash["position"], path),
          values.rhythmic_value(voice_event_hash["rhythmic_value"], path),
          values.voice_event_sounds(voice_event_hash, path)
        )
        voice_event.beam_break_before = voice_event_hash["beam_break_before"] if voice_event_hash.key?("beam_break_before")
        syllables = values.voice_event_syllables(voice_event_hash, path)
        raise ArgumentError, "#{path}: a rest cannot carry syllables" if voice_event.rest? && syllables.any?

        syllables.each do |syllable|
          voice_event.sing(syllable.text, verse: syllable.verse, hyphen_after: syllable.hyphen_after)
        end
        apply_markings(voice_event, voice_event_hash, path)
      end
    end

    def apply_markings(voice_event, voice_event_hash, path)
      articulations = values.catalog_keys(voice_event_hash["articulations"], HeadMusic::Rudiment::Articulation, "articulations", path)
      ornaments = values.catalog_keys(voice_event_hash["ornaments"], HeadMusic::Rudiment::Ornament, "ornaments", path)
      note_dynamic = values.note_dynamic(voice_event_hash["note_dynamic"], "#{path}.note_dynamic")
      return if articulations.empty? && ornaments.empty? && note_dynamic.nil?
      raise ArgumentError, "#{path}: a rest cannot carry articulations, ornaments, or a note dynamic" if voice_event.rest?

      voice_event.articulate(*articulations).embellish(*ornaments)
      voice_event.note_dynamic = note_dynamic
    end

    # Each dynamic event is placed through the public API, so a duplicate
    # position raises as it would for a caller, but with the document path.
    def place_dynamic_events(target, container_hash, path)
      values.dynamic_events(container_hash["dynamic_events"], path).each_with_index do |(position, level), index|
        target.place_dynamic(position, level)
      rescue ArgumentError => e
        raise ArgumentError, "#{path}.dynamic_events[#{index}]: #{e.message}"
      end
    end

    # Added after the voice events, whose positions a span's ends must find.
    def add_spans(voice, voice_hash, path)
      values.spans(voice_hash["spans"], path).each_with_index do |(kind, from, to), index|
        voice.add_span(kind, from: from, to: to)
      rescue ArgumentError => e
        raise ArgumentError, "#{path}.spans[#{index}]: #{e.message}"
      end
    end

    def apply_repeat_flags(flow)
      each_change(bar_hashes, "bars") do |bar_number, bar_hash, _path|
        bar = flow.bars(bar_number).last
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
