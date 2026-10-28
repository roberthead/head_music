module HeadMusic::Notation::MEI
  # The <verse> and <syl> of each sung note, on the first piece of its attack
  # and, in a chord, on its lowest note. A syllable's place in its word comes
  # from its own hyphen and the previous sung syllable's in the same verse.
  # @con is "d" for a hyphen, or "u" for a line over held notes; it holds
  # one, so a hyphenated melisma writes "d", and held notes write nothing.
  class LyricWriter
    def initialize(plan)
      @plan = plan
      @word_positions = plan.flow.voices.each_with_object({}.compare_by_identity) do |voice, positions|
        add_word_positions(voice, positions)
      end
    end

    def event_children(node)
      return [] unless sung_node?(node)

      voice_event = node.item.voice_event
      voice_event.syllables.keys.sort.map { |verse| verse_element(node.id, voice_event, verse) }
    end

    private

    attr_reader :plan, :word_positions

    def sung_node?(node)
      item = node.item
      node.kind == :note && !node.grace? && !%w[m t].include?(item.tie) &&
        item.voice_event.sung? && plan.note_ids(item).first.last == node.id
    end

    def verse_element(note_id, voice_event, verse)
      syllable = voice_event.syllable(verse)
      verse_id = plan.ids.child(note_id, "verse", verse)
      syl = Element.new(
        "syl", plan.ids.child(verse_id, "syl"),
        {"wordpos" => word_positions[voice_event][verse], "con" => connector(voice_event, syllable)},
        [], syllable.text
      )
      Element.new("verse", verse_id, {"n" => verse}, [syl])
    end

    def connector(voice_event, syllable)
      if syllable.hyphen_after?
        "d"
      elsif voice_event.melisma_continues_after?(syllable.verse)
        "u"
      end
    end

    def add_word_positions(voice, positions)
      previous = {}
      voice.voice_events.each do |voice_event|
        voice_event.syllables.each do |verse, syllable|
          positions[voice_event] ||= {}
          positions[voice_event][verse] = word_position(previous[verse]&.hyphen_after?, syllable.hyphen_after?)
          previous[verse] = syllable
        end
      end
    end

    def word_position(continues_word, hyphen_after)
      if continues_word
        hyphen_after ? "m" : "t"
      elsif hyphen_after
        "i"
      end
    end
  end

  EventWriter.child_sources << LyricWriter
end
