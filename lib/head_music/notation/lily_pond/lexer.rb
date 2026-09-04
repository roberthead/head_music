require "strscan"

# A namespace for LilyPond-notation parsing helpers
module HeadMusic::Notation::LilyPond
  # Splits a LilyPond document into tokens.
  #
  # LilyPond is brace-structured rather than line-structured, so one scanner
  # walks the whole document, skipping whitespace and comments as it goes
  # (never pre-stripped, so a % inside a string survives and line numbers
  # stay true). Notes, rests, and chord closers carry their duration; every
  # other construct is a single-purpose token. Constructs outside the
  # supported subset lex as :unsupported so the reader can name them where
  # it meets them, or skip them with the block they sit in.
  class Lexer
    DURATION_PATTERN = /(?:\d+|\\breve|\\longa|\\maxima)\.*/
    MULTIPLIER_PATTERN = %r{\*(\d+(?:/\d+)?)}
    # The Dutch contractions as/es/ases/eses come first so "es" is E-flat
    # rather than the letter e followed by a stray s; the lookahead keeps
    # words that start with a note letter (bass, alto, composer) whole.
    NOTE_PATTERN = /(?:(a|e)(ses|s)|([a-g])(isis|eses|is|es)?)(?![A-Za-z])('+|,+)?(#{DURATION_PATTERN})?(?:#{MULTIPLIER_PATTERN})?/o
    REST_PATTERN = /([rR])(?![A-Za-z])(#{DURATION_PATTERN})?(?:#{MULTIPLIER_PATTERN})?/o
    SPACER_PATTERN = /s(?![A-Za-z])#{DURATION_PATTERN}?/o
    CLOSE_CHORD_PATTERN = />(#{DURATION_PATTERN})?(?:#{MULTIPLIER_PATTERN})?/o
    STRING_PATTERN = /"((?:[^"\\]|\\.)*)"/m
    BLOCK_COMMENT_PATTERN = /%\{.*?%\}/m
    LINE_COMMENT_PATTERN = /%[^\n]*/
    COMMAND_PATTERN = /\\([A-Za-z]+)/
    WORD_PATTERN = /[A-Za-z_][A-Za-z0-9_]*/
    NUMBER_PATTERN = %r{\d+(?:/\d+)?}
    # Quarter-tone names (cih, ceh, cisih, ceseh) are real LilyPond pitches
    # the model cannot hold, so they are named as unsupported rather than
    # falling through as stray words.
    QUARTER_TONE_PATTERN = /[a-g](?:isih|eseh|ih|eh)(?![A-Za-z])(?:'+|,+)?#{DURATION_PATTERN}?/o
    UNSUPPORTED_PATTERN = /\\\\|#\S*|[\[\]()]|[-^_][.>^_+!-]?|[:!?]/

    ALIAS_SUFFIXES = {"s" => "es", "ses" => "eses"}.freeze

    SIMPLE_TOKENS = {
      "<<" => :open_parallel, ">>" => :close_parallel, "<" => :open_chord,
      "{" => :open_brace, "}" => :close_brace,
      "|" => :bar_check, "~" => :tie, "=" => :equals
    }.freeze
    SIMPLE_PATTERN = Regexp.union(SIMPLE_TOKENS.keys.sort_by { |key| -key.length })

    SNIPPET_LENGTH = 20

    def initialize(source)
      @source = normalize(source)
    end

    def tokens
      @tokens ||= scan
    end

    private

    attr_reader :scanner

    def normalize(source)
      text = source.to_s
      text = text.dup.force_encoding(Encoding::UTF_8) unless text.encoding == Encoding::UTF_8
      raise ParseError, "LilyPond input is not valid UTF-8" unless text.valid_encoding?

      text.delete_prefix("\uFEFF")
    end

    def scan
      @scanner = StringScanner.new(@source)
      @line = 1
      @line_start = 0
      tokens = []
      until scanner.eos?
        next if skip_insignificant

        tokens << next_token
      end
      tokens
    end

    def skip_insignificant
      consume(/\s+/) || skip_block_comment || consume(LINE_COMMENT_PATTERN)
    end

    def skip_block_comment
      return consume(BLOCK_COMMENT_PATTERN) if scanner.match?(BLOCK_COMMENT_PATTERN)
      return false unless scanner.match?(/%\{/)

      raise error("Unterminated block comment")
    end

    def next_token
      line = @line
      column = scanner.charpos - @line_start + 1
      read_token(line, column) || raise(error("Unexpected character #{scanner.peek(1).inspect} at column #{column}"))
    end

    def read_token(line, column)
      string_token(line, column) ||
        simple_token(line, column) ||
        close_chord_token(line, column) ||
        unsupported_token(line, column) ||
        command_token(line, column) ||
        note_token(line, column) ||
        rest_token(line, column) ||
        spacer_token(line, column) ||
        word_token(line, column) ||
        number_token(line, column)
    end

    def string_token(line, column)
      if consume(STRING_PATTERN)
        token(:string, line, column, lexeme: StringText.unescape(scanner[1]))
      elsif scanner.match?(/"/)
        raise error("Unterminated string")
      end
    end

    def simple_token(line, column)
      lexeme = consume(SIMPLE_PATTERN)
      lexeme && token(SIMPLE_TOKENS.fetch(lexeme), line, column, lexeme: lexeme)
    end

    def close_chord_token(line, column)
      return unless consume(CLOSE_CHORD_PATTERN)

      token(:close_chord, line, column, lexeme: scanner.matched, duration: scanner[1], multiplier: scanner[2])
    end

    def unsupported_token(line, column)
      lexeme = consume(UNSUPPORTED_PATTERN) || consume(QUARTER_TONE_PATTERN)
      lexeme && token(:unsupported, line, column, lexeme: lexeme)
    end

    def command_token(line, column)
      consume(COMMAND_PATTERN) && token(:command, line, column, lexeme: scanner[1])
    end

    def note_token(line, column)
      return unless consume(NOTE_PATTERN)

      letter = scanner[1] || scanner[3]
      suffix = scanner[1] ? ALIAS_SUFFIXES.fetch(scanner[2]) : scanner[4]
      token(
        :note, line, column, lexeme: scanner.matched, letter: letter, suffix: suffix,
        octave_marks: scanner[5], duration: scanner[6], multiplier: scanner[7]
      )
    end

    def rest_token(line, column)
      return unless consume(REST_PATTERN)

      type = (scanner[1] == "R") ? :whole_bar_rest : :rest
      token(type, line, column, lexeme: scanner.matched, duration: scanner[2], multiplier: scanner[3])
    end

    def spacer_token(line, column)
      lexeme = consume(SPACER_PATTERN)
      lexeme && token(:unsupported, line, column, lexeme: lexeme)
    end

    def word_token(line, column)
      lexeme = consume(WORD_PATTERN)
      lexeme && token(:word, line, column, lexeme: lexeme)
    end

    def number_token(line, column)
      lexeme = consume(NUMBER_PATTERN)
      lexeme && token(:number, line, column, lexeme: lexeme)
    end

    def token(type, line, column, **fields)
      Token.new(type: type, line: line, column: column, **fields)
    end

    # Consumes a match and keeps the line bookkeeping true across any
    # newlines it spans (block comments, strings, whitespace runs).
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

    def error(message)
      ParseError.new(
        message,
        line_number: @line, column: scanner.charpos - @line_start + 1,
        snippet: scanner.peek(SNIPPET_LENGTH).lines.first&.chomp
      )
    end
  end
end
