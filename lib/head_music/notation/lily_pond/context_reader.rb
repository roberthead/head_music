# A namespace for LilyPond-notation parsing helpers
module HeadMusic::Notation::LilyPond
  # Reads the declaration of a Staff or Voice context — \new, the optional
  # context name, and the \with block that can name the instrument — and
  # the rules about where a context may appear. The music inside it is read
  # by the MusicReader that opened this one.
  class ContextReader
    CONTEXT_TYPES = %w[Staff Voice].freeze
    WITH_FIELDS = %w[instrumentName].freeze

    def initialize(cursor, document, music)
      @cursor = cursor
      @document = document
      @music = music
    end

    def read_new(context)
      opener = cursor.advance
      type = cursor.expect(:word, "\\new expects a context type")
      unless CONTEXT_TYPES.include?(type.lexeme)
        raise cursor.unsupported(%(\\new #{type.lexeme} contexts are not supported), type)
      end

      skip_context_name
      child = VoiceContext.new(document, role(context, type), explicit: true)
      context.children += 1
      music.nested(opener) { music.read_expression(child) }
      child.close
    end

    # Each parallel item must open a context; parallel bare music is voice
    # separation the model cannot represent.
    def read_parallel_item(context)
      token = cursor.peek
      raise cursor.unsupported_token(token) if token.type == :unsupported

      case token.type == :command && token.lexeme
      when "new" then read_new(context)
      when "relative" then music.read_relative { read_parallel_item(context) }
      when "absolute" then music.read_absolute { read_parallel_item(context) }
      else raise cursor.unsupported("Simultaneous music without \\new contexts is not supported", token)
      end
    end

    # LilyPond starts a context where the sequence around it has reached,
    # but a stream always starts at bar one, so a context inside a sequence
    # is only placed correctly when it is the whole of that sequence.
    def read_sequential_new(context)
      raise cursor.unsupported("A \\new context that follows music in a sequence is not supported", cursor.peek) if context.stream.music?

      read_new(context)
      return if cursor.peek&.type == :close_brace

      raise cursor.unsupported("Music that follows a \\new context in a sequence is not supported", cursor.peek)
    end

    private

    attr_reader :cursor, :document, :music

    # A Voice with no name of its own belongs to the staff that holds it.
    def role(context, type)
      with_role || (context.role if type.lexeme == "Voice")
    end

    def skip_context_name
      return unless cursor.peek&.type == :equals

      cursor.advance
      cursor.expect(:string, "A context name must be a quoted string")
    end

    def with_role
      return unless cursor.peek&.type == :command && cursor.peek.lexeme == "with"

      cursor.advance
      cursor.expect(:open_brace, "\\with expects a block")
      role = nil
      AssignmentReader.new(cursor, "\\with", WITH_FIELDS).read do |name, value|
        role = value if name == "instrumentName"
      end
      role
    end
  end
end
