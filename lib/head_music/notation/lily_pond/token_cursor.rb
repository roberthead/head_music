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

    def eos?
      @index >= @tokens.length
    end

    def expect(type, message, unsupported: false)
      token = advance
      return token if token&.type == type

      raise(unsupported ? unsupported(message, token || peek(-1)) : error(message, token || peek(-1)))
    end

    # Consumes a command and the balanced block that follows it.
    def skip_block
      advance
      expect(:open_brace, "Expected a block")
      depth = 1
      while depth.positive?
        token = advance
        depth += 1 if token.type == :open_brace
        depth -= 1 if token.type == :close_brace
      end
    end

    def error(message, token)
      ParseError.new(message, line_number: token&.line, column: token&.column, snippet: token&.lexeme)
    end

    def unsupported(message, token)
      UnsupportedFeatureError.new(message, line_number: token&.line, column: token&.column, snippet: token&.lexeme)
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
