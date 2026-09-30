# A namespace for ABC-notation parsing helpers
module HeadMusic::Notation::ABC
  # The decorations written ahead of a voice's next note, chord, or rest, and
  # how each lands on the voice event it decorates.
  class PendingDecorations
    def initialize(voice)
      @voice = voice
      @waiting = []
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
    # mark. One the reader drops anyway, such as a !fermata! before a bar line,
    # is let go.
    def reject_dangling_decorations
      dangling = take.reject(&:dropped?).first
      return unless dangling

      raise ParseError.new(
        "A decoration must be followed by a note, chord, or rest",
        line_number: dangling.line, snippet: dangling.lexeme
      )
    end

    # A rest keeps only a level, which becomes a dynamic event at the rest.
    def apply(voice_event, decorations)
      decorations = decorations.select(&:level?) if voice_event.rest?
      decorations.each { |decoration| apply_decoration(voice_event, decoration) }
    end

    def place_level(position, decoration)
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
      when :level then place_level(voice_event.position, decoration)
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
