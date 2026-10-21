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
    # A field's value up to a comment, which a "%" in quotes does not begin.
    UNCOMMENTED_PATTERN = /\A(?:[^"%]|"[^"]*")*/

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
      field = field_token(line_text) unless continued
      return LineScanner.new(line_text, line_number, tokens).scan unless field

      tokens << Token.new(line: line_number, column: 1, **field)
      false
    end

    # Lines that are fields rather than music: V: switches voices, P: labels
    # a part, Q: sets the tempo; any other letter-colon line is a field we
    # don't interpret in the body. A note followed by a repeat bar (e.g. "A:|") also puts a colon
    # after a letter at line start, so bar-line characters after the colon
    # disqualify.
    def field_token(line_text)
      value = line_text[2..].to_s.split("%", 2).first.to_s.strip
      case line_text[0, 2]
      when "V:" then {type: :voice_change, voice_id: value}
      when "P:" then {type: :part_label, lexeme: value}
      when "Q:" then {type: :tempo, lexeme: line_text[2..][UNCOMMENTED_PATTERN].strip}
      when /\A[A-Za-z]:/
        {type: :unsupported, lexeme: line_text.strip[0, SNIPPET_LENGTH]} unless ["|", ":"].include?(line_text[2])
      end
    end
  end
end
