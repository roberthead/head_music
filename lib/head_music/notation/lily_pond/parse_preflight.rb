# A namespace for LilyPond-notation parsing helpers
module HeadMusic::Notation::LilyPond
  # Boundary checks the Parser runs before it reads a document, so a caller
  # never receives a reference to a partially built composition. Each check
  # raises on the first problem it finds and is otherwise a no-op.
  class ParsePreflight
    OPENERS = {open_brace: :close_brace, open_parallel: :close_parallel, open_chord: :close_chord}.freeze
    LEXEMES = {
      open_brace: "{", close_brace: "}",
      open_parallel: "<<", close_parallel: ">>",
      open_chord: "<", close_chord: ">"
    }.freeze

    # Checked on the raw bytes: String#strip raises on invalid UTF-8, and
    # that case belongs to the Lexer's encoding guard.
    def self.ensure_input_present(lily_pond_string)
      return unless lily_pond_string.to_s.b.strip.empty?

      raise ParseError, "LilyPond input is blank"
    end

    # Braces, << >>, and chord brackets must nest; an unmatched opener is
    # reported at its own line, since that is where the author must look.
    def self.ensure_balanced_delimiters(tokens)
      open = []
      tokens.each do |token|
        if OPENERS.key?(token.type)
          open << token
        elsif OPENERS.value?(token.type)
          opener = open.pop
          unless opener && OPENERS[opener.type] == token.type
            raise unbalanced_error(token, "Unexpected")
          end
        end
      end
      raise unbalanced_error(open.last, "Unclosed") if open.any?
    end

    def self.unbalanced_error(token, adjective)
      lexeme = LEXEMES.fetch(token.type)
      ParseError.new(
        %(#{adjective} "#{lexeme}"),
        line_number: token.line, column: token.column, snippet: lexeme
      )
    end
    private_class_method :unbalanced_error
  end
end
