# A namespace for ABC-notation parsing helpers
module HeadMusic::Notation::ABC
  # Boundary checks the Parser runs before it interprets a tune, so a caller
  # never receives a reference to a partially built composition. Each check
  # raises on the first problem it finds and is otherwise a no-op. They run at
  # distinct points of construction — blank input before the header is read,
  # trailing content once the header exists, unsupported tokens after lexing —
  # so each takes exactly the input it inspects rather than sharing state.
  class Preflight
    def self.ensure_input_present(abc_string)
      return unless abc_string.to_s.strip.empty?

      raise ParseError, "ABC input is blank"
    end

    # The lexer treats a blank line as the end of the tune, so anything
    # after it would be silently dropped — most likely another tune.
    def self.reject_content_after_tune(header)
      lines = header.body.lines
      blank_index = lines.find_index { |line| line.strip.empty? }
      return unless blank_index

      extra_lines = lines[(blank_index + 1)..]
      extra_index = extra_lines.find_index do |line|
        stripped = line.strip
        !stripped.empty? && !stripped.start_with?("%")
      end
      return unless extra_index

      raise ParseError.new(
        "Content after the tune body; parse a book of tunes with ABC.parse_book",
        line_number: header.body_start_line + blank_index + 1 + extra_index,
        snippet: extra_lines[extra_index].strip[0, BodyLexer::SNIPPET_LENGTH]
      )
    end

    def self.reject_unsupported_tokens(tokens)
      token = tokens.find { |candidate| candidate.type == :unsupported }
      return unless token

      lexeme = token.lexeme
      raise UnsupportedFeatureError.new(
        "Unsupported ABC feature #{lexeme.inspect}",
        line_number: token.line, snippet: lexeme
      )
    end
  end
end
