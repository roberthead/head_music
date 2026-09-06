# A namespace for LilyPond-notation parsing helpers
module HeadMusic::Notation::LilyPond
  # Reads one music expression by recursive descent: sequential braces,
  # << >> parallels, and \relative and \absolute wrappers. A ContextReader
  # reads the \new Staff and \new Voice declarations inside, and a
  # MusicItemReader the notes, rests, and commands. Every other command
  # raises as unsupported rather than being skipped, because skipping a
  # \transpose or a \tuplet would yield a plausible but wrong flow.
  class MusicReader
    # The reader recurses per brace level and per \relative, \absolute, or
    # \new wrapper; the lexer and balance check do not, so nesting must be
    # bounded here to stay inside ParseError.
    MAX_NESTING_DEPTH = 1000
    DEFAULT_RELATIVE_REFERENCE = "F3"

    def initialize(cursor, document)
      @cursor = cursor
      @readers = PitchReaderStack.new
      @items = MusicItemReader.new(cursor, @readers)
      @contexts = ContextReader.new(cursor, document, self)
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

    def nested(opener)
      @depth += 1
      raise cursor.error("Music expressions are nested too deeply", opener) if @depth > MAX_NESTING_DEPTH

      yield
      @depth -= 1
    end

    private

    attr_reader :cursor, :readers, :items, :contexts

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
      raise cursor.unsupported("Simultaneous music inside \\relative is not supported", token) if readers.current.relative?

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
      token = cursor.peek
      case token.type
      when :note then items.read_note(context)
      when :rest then items.read_rest(context)
      when :whole_bar_rest then items.read_whole_bar_rest(context)
      when :open_chord then items.read_chord(context)
      when :tie then items.read_tie(context)
      when :bar_check then items.read_bar_check(context)
      when :open_brace then read_sequential(context)
      when :open_parallel then read_parallel(context)
      when :command then read_item_command(context)
      when :unsupported then raise cursor.unsupported_token(token)
      else raise cursor.error(%(Unexpected token "#{token.lexeme}"), token)
      end
    end

    def read_item_command(context)
      token = cursor.peek
      case token.lexeme
      when "key" then items.read_key(context)
      when "time" then items.read_time(context)
      when "clef" then items.read_clef
      when "relative" then read_relative { read_expression(context) }
      when "absolute" then read_absolute { read_expression(context) }
      when "new" then contexts.read_sequential_new(context)
      when *ENVELOPE_COMMANDS then raise cursor.error(%(Unexpected \\#{token.lexeme} inside music), token)
      else raise cursor.unsupported_command(token)
      end
    end
  end
end
