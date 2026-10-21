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
    # words that start with a note letter (bass, alto, composer) whole. A
    # forced (!) or cautionary (?) accidental only chooses what is printed,
    # so it is read and dropped.
    NOTE_PATTERN = /(?:(a|e)(ses|s)|([a-g])(isis|eses|is|es)?)(?![A-Za-z])('+|,+)?[!?]?(#{DURATION_PATTERN})?(?:#{MULTIPLIER_PATTERN})?/o
    REST_PATTERN = /([rR])(?![A-Za-z])(#{DURATION_PATTERN})?(?:#{MULTIPLIER_PATTERN})?/o
    SPACER_PATTERN = /s(?![A-Za-z])(#{DURATION_PATTERN})?(?:#{MULTIPLIER_PATTERN})?/o
    CLOSE_CHORD_PATTERN = />(#{DURATION_PATTERN})?(?:#{MULTIPLIER_PATTERN})?/o
    STRING_PATTERN = /"((?:[^"\\]|\\.)*)"/m
    COMMAND_PATTERN = /\\([A-Za-z]+)/
    AFTER_PATTERN = /\\after(?![A-Za-z])/
    AFTER_DURATION_PATTERN = /(#{DURATION_PATTERN})(?:#{MULTIPLIER_PATTERN})?/o
    TUPLET_PATTERN = /\\(tuplet|times)(?![A-Za-z])/
    TUPLET_SPAN_PATTERN = /\\tupletSpan(?![A-Za-z])/
    FRACTION_PATTERN = %r{\d+/\d+}
    WORD_PATTERN = /[A-Za-z_][A-Za-z0-9_]*/
    NUMBER_PATTERN = %r{\d+(?:/\d+)?}
    # The metronome mark of a \tempo, as 4. = 60, or a range, as 4 = 100-120.
    METRONOME_PATTERN = /(\d+\.*)\s*=\s*(\d+)(?:\s*-\s*(\d+))?/
    # Inside a markup, a word runs to the next space, brace, quote, or
    # command, so "rit." is one word.
    MARKUP_WORD_PATTERN = /[^\s{}"\\#%\d][^\s{}"\\#%]*/
    # Quarter-tone names (cih, ceh, cisih, ceseh) are real LilyPond pitches
    # the model cannot hold, so they are named as unsupported rather than
    # falling through as stray words.
    QUARTER_TONE_PATTERN = /[a-g](?:isih|eseh|ih|eh)(?![A-Za-z])(?:'+|,+)?#{DURATION_PATTERN}?/o
    # \< \> \! are hairpins, written after a note like a mark, as are the
    # phrasing slur \( \) and a slur named with \=, as \=1( or \=1\(.
    MARK_PATTERN = /\\=[A-Za-z0-9]+\\?[()]|\\[()<>!]|\\\\|#\S*|[\[\]()]|[-^_][.>^_+!-]?|[:!?]/
    UNSUPPORTED_PATTERN = Regexp.union(MARK_PATTERN, QUARTER_TONE_PATTERN)

    ALIAS_SUFFIXES = {"s" => "es", "ses" => "eses"}.freeze

    SIMPLE_TOKENS = {
      "<<" => :open_parallel, ">>" => :close_parallel, "<" => :open_chord,
      "{" => :open_brace, "}" => :close_brace,
      "|" => :bar_check, "~" => :tie, "=" => :equals
    }.freeze
    SIMPLE_PATTERN = Regexp.union(SIMPLE_TOKENS.keys.sort_by { |key| -key.length })

    def initialize(source)
      @source = source
    end

    def tokens
      @tokens ||= scan
    end

    private

    attr_reader :scanner

    delegate :consume, to: :scanner, private: true

    def scan
      @scanner = SourceScanner.new(@source)
      @markup_depth = nil
      tokens = []
      until scanner.eos?
        next if scanner.skip_insignificant

        tokens << next_token
      end
      tokens
    end

    # A token is stamped with where it began, remembered here because
    # consuming its lexeme moves the scanner past it.
    def next_token
      @token_line = scanner.line
      @token_column = scanner.column
      token = (@markup_depth && markup_word_token) || read_token || raise(scanner.unexpected_character_error)
      follow_markup(token)
      token
    end

    def read_token
      string_token || simple_token || close_chord_token ||
        lexeme_token(UNSUPPORTED_PATTERN, :unsupported) || after_token || tuplet_token || tuplet_span_token || command_token ||
        note_token || rest_token || spacer_token ||
        lexeme_token(WORD_PATTERN, :word) || metronome_token || lexeme_token(NUMBER_PATTERN, :number)
    end

    def markup_word_token
      lexeme_token(MARKUP_WORD_PATTERN, :word)
    end

    # A markup is its commands and their Scheme arguments, then a string, a
    # word, or a braced block, inside which words are markup words too.
    def follow_markup(token)
      if token.is?(:command, "markup")
        @markup_depth ||= 0
      elsif @markup_depth
        @markup_depth += 1 if token.type == :open_brace
        @markup_depth -= 1 if token.type == :close_brace
        @markup_depth = nil if @markup_depth.zero? && !markup_argument?(token)
      end
    end

    def markup_argument?(token)
      %i[command open_brace].include?(token.type) || token.is?(:unsupported, /\A#/)
    end

    def metronome_token
      return unless consume(METRONOME_PATTERN)

      token(:metronome, lexeme: scanner.matched, duration: scanner[1])
    end

    def string_token
      if consume(STRING_PATTERN)
        token(:string, lexeme: StringText.unescape(scanner[1]))
      elsif scanner.match?(/"/)
        raise scanner.error("Unterminated string")
      end
    end

    def simple_token
      lexeme = consume(SIMPLE_PATTERN)
      lexeme && token(SIMPLE_TOKENS.fetch(lexeme), lexeme: lexeme)
    end

    def close_chord_token
      consume(CLOSE_CHORD_PATTERN) && timed_token(:close_chord, 1)
    end

    def command_token
      consume(COMMAND_PATTERN) && token(:command, lexeme: scanner[1])
    end

    # \after takes a duration, which may be dotted or multiplied, so it is
    # read with the command rather than left to the number pattern.
    def after_token
      consume(AFTER_PATTERN) && token(:after, lexeme: "\\after", **argument_duration)
    end

    # \tuplet n/d and \times d/n both lex with the fraction as written; only
    # \tuplet takes the optional span duration that follows it.
    def tuplet_token
      return unless consume(TUPLET_PATTERN)

      command = scanner[1]
      skip_insignificant_run
      fraction = consume(FRACTION_PATTERN)
      span = (command == "tuplet" && fraction) ? argument_duration : {}
      token(:tuplet, lexeme: "\\#{command}", fraction: fraction, **span)
    end

    # \tupletSpan's \default is left to the reader, as a command token.
    def tuplet_span_token
      consume(TUPLET_SPAN_PATTERN) && token(:tuplet_span, lexeme: "\\tupletSpan", **argument_duration)
    end

    def argument_duration
      skip_insignificant_run
      duration, multiplier = consume(AFTER_DURATION_PATTERN) && scanner.captures
      {duration: duration, multiplier: multiplier}
    end

    def skip_insignificant_run
      nil while scanner.skip_insignificant
    end

    def note_token
      return unless consume(NOTE_PATTERN)

      alias_letter, alias_suffix, letter, suffix, octave_marks, duration, multiplier = scanner.captures
      token(
        :note, lexeme: scanner.matched,
        letter: alias_letter || letter, suffix: alias_letter ? ALIAS_SUFFIXES.fetch(alias_suffix) : suffix,
        octave_marks: octave_marks, duration: duration, multiplier: multiplier
      )
    end

    def rest_token
      consume(REST_PATTERN) && timed_token((scanner[1] == "R") ? :whole_bar_rest : :rest, 2)
    end

    def spacer_token
      consume(SPACER_PATTERN) && timed_token(:spacer, 1)
    end

    # A token whose lexeme ends in an optional duration and multiplier, the
    # capture groups from the given one onward.
    def timed_token(type, duration_group)
      token(type, lexeme: scanner.matched, duration: scanner[duration_group], multiplier: scanner[duration_group + 1])
    end

    def lexeme_token(pattern, type)
      lexeme = consume(pattern)
      lexeme && token(type, lexeme: lexeme)
    end

    def token(type, **fields)
      Token.new(type: type, line: @token_line, column: @token_column, **fields)
    end
  end
end
