# A namespace for ABC-notation parsing helpers
module HeadMusic::Notation::ABC
  # Tokenizes the body of an ABC tune (the text after the K: header line).
  #
  # Emits flat value tokens rather than a tree so the parser can decide
  # how much structure to build. Out-of-scope-but-valid ABC constructs are
  # emitted as :unsupported tokens (instead of raising here) so the parser
  # can raise UnsupportedFeatureError with knowledge of what it was.
  class BodyLexer
    SNIPPET_LENGTH = 20

    def initialize(body_text, start_line: 1)
      @body = body_text.to_s
      @start_line = start_line
      ensure_valid_encoding
    end

    def tokens
      @tokens ||= lex
    end

    private

    def ensure_valid_encoding
      return if @body.valid_encoding?

      raise ParseError.new("Tune body is not valid UTF-8", line_number: @start_line)
    end

    def lex
      tokens = []
      continued = false
      @body.lines.map(&:chomp).each_with_index do |line_text, index|
        break if line_text.strip.empty?

        continued = lex_line(line_text, @start_line + index, tokens, continued)
      end
      tokens
    end

    def lex_line(line_text, line_number, tokens, continued)
      return false if !continued && line_start_token(line_text, line_number, tokens)

      LineScanner.new(line_text, line_number, tokens).scan
    end

    # Handles lines that are fields rather than music: V: switches voices, P:
    # labels a part; any other letter-colon line is a field we don't interpret
    # in the body.
    def line_start_token(line_text, line_number, tokens)
      if line_text.start_with?("V:")
        tokens << voice_change_token(line_text, line_number)
        return true
      end
      if line_text.start_with?("P:")
        tokens << part_label_token(line_text, line_number)
        return true
      end
      if header_field_line?(line_text)
        tokens << Token.new(
          type: :unsupported, line: line_number, column: 1,
          lexeme: line_text.strip[0, SNIPPET_LENGTH]
        )
        return true
      end
      false
    end

    # A note followed by a repeat bar (e.g. "A:|") also puts a colon after a
    # letter at line start, so bar-line characters after the colon disqualify.
    def header_field_line?(line_text)
      line_text.match?(/\A[A-Za-z]:/) && !["|", ":"].include?(line_text[2])
    end

    def voice_change_token(line_text, line_number)
      voice_id = line_text.delete_prefix("V:").split("%", 2).first.to_s.strip
      Token.new(type: :voice_change, line: line_number, column: 1, voice_id: voice_id)
    end

    def part_label_token(line_text, line_number)
      label = line_text.delete_prefix("P:").split("%", 2).first.to_s.strip
      Token.new(type: :part_label, line: line_number, column: 1, lexeme: label)
    end
  end
end
