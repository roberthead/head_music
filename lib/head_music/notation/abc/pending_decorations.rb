# A namespace for ABC-notation parsing helpers
module HeadMusic::Notation::ABC
  # The decorations written ahead of a voice's next note, chord, or rest, and
  # how each lands on the voice event it decorates.
  class PendingDecorations
    def initialize(voice, fermata_marks)
      @voice = voice
      @waiting = []
      @hairpin_marks = HairpinMarks.new(voice)
      @fermata_marks = fermata_marks
      @held_links = []
    end

    def decorate(decoration)
      @waiting << decoration
    end

    def take
      decorations = @waiting
      @waiting = []
      decorations
    end

    # A navigation sign or instruction marks a bar, not a voice event, so the
    # parser takes it wherever it can tell which bar is meant.
    def take_navigation
      navigation, @waiting = @waiting.partition(&:navigation?)
      navigation
    end

    # A marking before a bar line, tie, or the end of the tune has nothing to
    # mark. One the reader drops anyway, such as a bowing before a bar line,
    # is let go, and a fermata is answered, for the note before it. A hairpin
    # mark waits for the next note: before a tie, that is the tie's later
    # link, where the mark stands.
    def reject_dangling_decorations
      hairpins, others = take.partition(&:hairpin?)
      @waiting = hairpins
      fermatas, others = others.partition(&:fermata?)
      dangling = others.reject(&:dropped?).first
      return fermatas unless dangling

      raise ParseError.new(
        "A decoration must be followed by a note, chord, or rest",
        line_number: dangling.line, snippet: dangling.lexeme
      )
    end

    # A tied note's later link, starting at the position, keeps its fermata
    # and its level and hairpin marks where it starts: a fermata holds from
    # there once the note is placed. Its other markings, returned, join the
    # whole event's.
    def mark_link(position, decorations)
      fermatas, decorations = decorations.partition(&:fermata?)
      @held_links << position if fermatas.any?
      marks, markings = decorations.partition(&:positional?)
      marks.each { |decoration| place_mark(position, decoration) }
      markings
    end

    def hold(voice_event, from: voice_event.position)
      @fermata_marks.add(voice_event, from: from)
    end

    def hold_last
      last_voice_event = @voice.last_voice_event
      hold(last_voice_event) if last_voice_event
    end

    # A hairpin mark before a bar line or the end of the voice marks where
    # the music has reached, as one ending with the music does.
    def settle_hairpins(position)
      hairpins, @waiting = @waiting.partition(&:hairpin?)
      hairpins.each { |decoration| place_mark(position, decoration) }
    end

    def add_hairpins
      @hairpin_marks.add_spans
    end

    # A rest keeps only what marks a moment: a level, which becomes a dynamic
    # event at the rest, a hairpin mark, and a fermata.
    def apply(voice_event, decorations)
      fermatas, decorations = decorations.partition(&:fermata?)
      hold(voice_event) if fermatas.any?
      @held_links.each { |from| hold(voice_event, from: from) }
      @held_links = []
      decorations = decorations.select(&:positional?) if voice_event.rest?
      decorations.each { |decoration| apply_decoration(voice_event, decoration) }
    end

    # An invisible rest or spacer holds only what marks a moment.
    def place_at(position)
      take.select(&:positional?).each { |decoration| place_mark(position, decoration) }
    end

    def place_mark(position, decoration)
      return @hairpin_marks.record(position, decoration) if decoration.hairpin?

      @voice.place_dynamic(position, decoration.key)
    rescue ArgumentError => error
      raise ParseError.new(error.message, line_number: decoration.line, snippet: decoration.lexeme)
    end

    private

    def apply_decoration(voice_event, decoration)
      key = decoration.key
      case decoration.kind
      when :articulation then voice_event.articulate(key)
      when :ornament then voice_event.embellish(key)
      when :note_dynamic then assign_note_dynamic(voice_event, decoration)
      when :level, :hairpin_start, :hairpin_end then place_mark(voice_event.position, decoration)
      end
    end

    def assign_note_dynamic(voice_event, decoration)
      if voice_event.note_dynamic
        raise ParseError.new(
          "A note may carry only one of sf, sfz, rfz, and fp",
          line_number: decoration.line, snippet: decoration.lexeme
        )
      end
      voice_event.note_dynamic = decoration.key
    end
  end
end
