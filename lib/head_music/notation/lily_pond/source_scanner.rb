require "strscan"

# A namespace for LilyPond-notation parsing helpers
module HeadMusic::Notation::LilyPond
  # A StringScanner over a LilyPond source that knows where it is.
  #
  # The line and column of the scan position stay true across every consumed
  # match -- block comments, strings, and whitespace runs all span newlines --
  # so a token can be stamped with where it began and an error can say where
  # it happened. Comments are skipped here rather than pre-stripped, so a %
  # inside a string survives and the line numbers stay true.
  class SourceScanner
    BLOCK_COMMENT_PATTERN = /%\{.*?%\}/m
    LINE_COMMENT_PATTERN = /%[^\n]*/
    SNIPPET_LENGTH = 20

    attr_reader :line

    delegate :eos?, :match?, :peek, :matched, to: :scanner

    def initialize(source)
      @scanner = StringScanner.new(normalize(source))
      @line = 1
      @line_start = 0
    end

    def column
      scanner.charpos - @line_start + 1
    end

    def [](group)
      scanner[group]
    end

    # StringScanner#captures answers "" for a group that took no part in the
    # match, where #[] answers nil, and nil is what a caller can test.
    def captures
      (1...scanner.size).map { |group| scanner[group] }
    end

    def consume(pattern)
      start = scanner.charpos
      text = scanner.scan(pattern)
      return unless text

      newlines = text.count("\n")
      if newlines.positive?
        @line += newlines
        @line_start = start + text.rindex("\n") + 1
      end
      text
    end

    # Whitespace and comments: what the language ignores between tokens.
    def skip_insignificant
      consume(/\s+/) || skip_block_comment || consume(LINE_COMMENT_PATTERN)
    end

    def skip_block_comment
      return consume(BLOCK_COMMENT_PATTERN) if match?(BLOCK_COMMENT_PATTERN)
      return false unless match?(/%\{/)

      raise error("Unterminated block comment")
    end

    def error(message)
      ParseError.new(
        message,
        line_number: line, column: column,
        snippet: scanner.peek(SNIPPET_LENGTH).lines.first&.chomp
      )
    end

    def unexpected_character_error
      error("Unexpected character #{peek(1).inspect} at column #{column}")
    end

    private

    attr_reader :scanner

    def normalize(source)
      text = source.to_s
      text = text.dup.force_encoding(Encoding::UTF_8) unless text.encoding == Encoding::UTF_8
      raise ParseError, "LilyPond input is not valid UTF-8" unless text.valid_encoding?

      text.delete_prefix("\uFEFF")
    end
  end
end
