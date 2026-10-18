# A namespace for LilyPond-notation parsing helpers
module HeadMusic::Notation::LilyPond
  # Reads one music expression by recursive descent: sequential braces,
  # << >> parallels, and \relative and \absolute wrappers. A ContextReader
  # reads the \new Staff and \new Voice declarations inside, a
  # VoiceItemReader each item of a voice, and a DynamicsItemReader what a
  # \new Dynamics holds. Every other command raises as unsupported rather
  # than being skipped, because skipping a \transpose would yield a
  # plausible but wrong flow.
  class MusicReader
    # The reader recurses per brace level and per \relative, \absolute, or
    # \new wrapper; the lexer and balance check do not, so nesting must be
    # bounded here to stay inside ParseError.
    MAX_NESTING_DEPTH = 1000
    DEFAULT_RELATIVE_REFERENCE = "F3"
    TUPLET_TOKENS = %i[tuplet tuplet_span].freeze

    def initialize(cursor, document)
      @cursor = cursor
      @readers = PitchReaderStack.new
      @contexts = ContextReader.new(cursor, document, self)
      items = MusicItemReader.new(cursor, @readers)
      settings = SettingReader.new(cursor)
      bar_marks = BarMarkReader.new(cursor)
      @voice_items = VoiceItemReader.new(
        cursor, self, items: items, settings: settings, bar_marks: bar_marks, contexts: @contexts, tuplets: TupletReader.new(cursor)
      )
      @dynamics_items = DynamicsItemReader.new(cursor, self, items, settings: settings, bar_marks: bar_marks)
      @depth = 0
    end

    def read_expression(context)
      token = cursor.peek
      case token&.type
      when :open_brace then read_sequential(context)
      when :open_parallel then read_parallel(context)
      when :command then read_expression_command(context)
      when :unsupported then raise cursor.unsupported_token(token)
      else raise cursor.error("Expected a music expression", token)
      end
    end

    # \relative and \absolute wrap a music expression, so the readers that
    # descend into one — this one and the ContextReader — enter the wrapper
    # through here.
    def read_relative(&block)
      token = cursor.advance
      readers.relative(relative_reference) { nested(token, &block) }
    end

    def read_absolute(&block)
      token = cursor.advance
      readers.absolute { nested(token, &block) }
    end

    def relative?
      readers.current.relative?
    end

    def nested(opener)
      @depth += 1
      raise cursor.error("Music expressions are nested too deeply", opener) if @depth > MAX_NESTING_DEPTH

      yield
      @depth -= 1
    end

    def reject_inside_tuplet(context, name, token)
      raise cursor.unsupported("#{name} inside a tuplet is not supported", token) if context.stream.tuplet?
    end

    private

    attr_reader :cursor, :readers, :voice_items, :dynamics_items, :contexts

    def read_expression_command(context)
      token = cursor.peek
      case token.lexeme
      when "relative" then read_relative { read_expression(context) }
      when "absolute" then read_absolute { read_expression(context) }
      when "new" then contexts.read_new(context)
      else raise cursor.unsupported_command(token)
      end
    end

    def read_sequential(context)
      nested(cursor.advance) do
        read_item(context) until cursor.peek.type == :close_brace
      end
      cursor.advance
    end

    def read_parallel(context)
      token = cursor.advance
      reject_inside_tuplet(context, "Simultaneous music", token)
      raise cursor.unsupported("Simultaneous music inside \\relative is not supported", token) if relative?

      context.preceding_staff = nil
      nested(token) do
        contexts.read_parallel_item(context) until cursor.peek.type == :close_parallel
      end
      cursor.advance
    end

    def relative_reference
      return HeadMusic::Rudiment::Pitch.get(DEFAULT_RELATIVE_REFERENCE) unless cursor.peek&.type == :note

      token = cursor.advance
      raise cursor.error("\\relative expects a pitch", token) if token.duration || token.multiplier

      PitchReader.absolute.pitch(token)
    end

    def read_item(context)
      return voice_items.read(context) unless context.dynamics?

      token = cursor.peek
      raise cursor.unsupported_token(token) if TUPLET_TOKENS.include?(token.type)

      dynamics_items.read(context)
    end
  end
end
