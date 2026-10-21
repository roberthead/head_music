# A namespace for LilyPond-notation parsing helpers
module HeadMusic::Notation::LilyPond
  # The readers' shared place in the token list, and the errors they raise
  # from there. Every ParseError carries the line, column, and lexeme of the
  # token it was raised at, so the cursor builds them rather than each
  # reader that navigates with it.
  class TokenCursor
    def initialize(tokens)
      @tokens = tokens
      @index = 0
    end

    def peek(offset = 0)
      @tokens[@index + offset]
    end

    def advance
      token = @tokens[@index]
      @index += 1 if token
      token
    end

    # Consumes the next token if it is of the type given.
    def accept(type)
      advance if peek&.type == type
    end

    def eos?
      @index >= @tokens.length
    end

    def expect(type, message, unsupported: false)
      token = advance
      return token if token&.type == type

      at = token || peek(-1)
      raise(unsupported ? unsupported(message, at) : error(message, at))
    end

    # Consumes a command and the balanced block that follows it.
    def skip_block
      advance
      skip_braces("Expected a block")
    end

    def markup?
      peek&.is?(:command, "markup")
    end

    # A markup is free text the model cannot hold: its function commands,
    # then a string, a word, or a block.
    def skip_markup
      markup_text
      nil
    end

    # The plain words of a markup, its strings and words in order, without
    # the commands that set them.
    def markup_text
      advance
      advance while peek&.type == :command
      case peek&.type
      when :open_brace then braced_words("\\markup expects a string or a block").join(" ")
      when :string, :word then advance.lexeme
      else raise error("\\markup expects a string or a block", peek || peek(-1))
      end
    end

    def skip_braces(message)
      braced_words(message)
      nil
    end

    # The strings and words of a balanced block, which it consumes.
    def braced_words(message)
      expect(:open_brace, message)
      depth = 1
      words = []
      while depth.positive?
        token = advance
        depth += 1 if token.type == :open_brace
        depth -= 1 if token.type == :close_brace
        words << token.lexeme if %i[string word].include?(token.type)
      end
      words
    end

    def error(message, token)
      ParseError.new(message, line_number: token&.line, column: token&.column, snippet: token&.lexeme)
    end

    def unsupported(message, token)
      UnsupportedFeatureError.new(message, line_number: token&.line, column: token&.column, snippet: token&.lexeme)
    end

    # The error for a token nothing reads where it stands: an unsupported
    # command or construct, else the message given.
    def unexpected(token, message)
      case token&.type
      when :command then unsupported_command(token)
      when :unsupported then unsupported_token(token)
      else error(message, token || peek(-1))
      end
    end

    def unsupported_command(token)
      UnsupportedFeatureError.new(
        %(Unsupported LilyPond feature "\\#{token.lexeme}"),
        line_number: token.line, column: token.column, snippet: "\\#{token.lexeme}"
      )
    end

    # A construct the lexer could name but the model cannot hold. It is
    # reported where the reader meets it, so the same construct inside a
    # block the reader skips costs nothing.
    def unsupported_token(token)
      unsupported(%(Unsupported LilyPond feature "#{token.lexeme}"), token)
    end
  end
end
