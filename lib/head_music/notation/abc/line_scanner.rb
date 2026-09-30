require "strscan"

# A namespace for ABC-notation parsing helpers
module HeadMusic::Notation::ABC
  # Scans one line of tune music into tokens, appending them to the tune's
  # token list, which it also reads back to decide whether a space breaks a
  # beam.
  class LineScanner
    # Alternatives are ordered longest-first so the scanner never takes a
    # short match when a longer bar line is present (e.g. "|]" before "|").
    BAR_LINE_PATTERN = /:\|\|:|:\|:|::|:\||\|:|\|\||\|\]|\[\||\|/

    # ":||:" and ":|:" are alternate spellings of the double repeat "::".
    NORMALIZED_BAR_STYLES = {":||:" => "::", ":|:" => "::"}.freeze

    NOTE_PATTERN = %r{(\^\^|\^|__|_|=)?([A-Ga-g])([',]*)([\d/]*)}
    # An inline field ("[K:...]"), tried closed before its unterminated fallback.
    INLINE_FIELD_PATTERNS = [/\[[A-Za-z]:[^\]]*\]/, /\[[A-Za-z]:[^\]]*/].freeze
    REST_PATTERN = %r{z([\d/]*)}
    VOLTA_DIGITS_PATTERN = /\d[\d,-]*/

    # A decoration: "!trill!", its ABC 2.0 spelling "+trill+", or a one-character
    # shorthand. A dot decorates only a note, chord, rest, or another
    # decoration, since ".|" is a dotted bar line.
    DECORATION_PATTERNS = [
      /![^!\s]+!/, /\+[^+\s]+\+/, /[~HLMOPSTuv]/, /\.(?=[\^_=A-Ga-gz\[!+.~HLMOPSTuv])/
    ].freeze

    # A slur opens with "(", or ".(" for a dotted slur, unless a digit
    # follows, which makes a tuplet.
    SLUR_START_PATTERN = /\.?\((?!\d)/

    # Recognizable ABC we deliberately don't handle: grace notes ({..}),
    # tuplets, special rests (Z, x), dotted bar lines, and malformed
    # decorations. Ordered so a closed form is tried before its unterminated
    # fallback.
    UNSUPPORTED_PATTERNS = [
      /\{[^}]*\}/, /\{[^}]*/, /![^!]*!/, /![^!]*/,
      /\(\d/, /\./, /Z\d*/, %r{x[\d/]*}
    ].freeze

    # Music tokens whose whitespace successor breaks a beam group; other
    # tokens (bar lines, ties, etc.) already interrupt beaming on their own.
    BEAMABLE_TOKEN_TYPES = [:note, :rest, :chord].freeze

    # Tried in order; the first to consume input wins.
    TOKEN_SCANS = %i[
      scan_quoted_string scan_bar_line scan_bracket scan_note scan_rest
      scan_tie scan_broken_rhythm scan_slur scan_decoration scan_unsupported
    ].freeze

    def initialize(line_text, line_number, tokens)
      @scanner = StringScanner.new(line_text)
      @line_number = line_number
      @tokens = tokens
    end

    # Returns true when the line ends with a continuation backslash.
    def scan
      until @scanner.eos?
        spaced = @scanner.skip(/[ \t]+/)
        break if @scanner.skip(/%/)
        return true if @scanner.skip(/\\[ \t]*\z/)
        break if @scanner.eos?

        add(:beam_break) if spaced && beamable_predecessor?
        scan_token
      end
      false
    end

    private

    # A beam break only matters after a music token; whitespace elsewhere
    # (leading, after a bar line) carries no beaming signal. A slur's close
    # sits between a note and the space after it, so it is looked past.
    def beamable_predecessor?
      token = @tokens.reverse_each.find { |candidate| candidate.type != :slur_end }
      !token.nil? && BEAMABLE_TOKEN_TYPES.include?(token.type)
    end

    def scan_token
      column = @scanner.pos + 1
      return if TOKEN_SCANS.any? { |scan| send(scan, column) }

      raise_unexpected_character(column)
    end

    def add(type, column: @scanner.pos + 1, **attributes)
      @tokens << Token.new(type: type, line: @line_number, column: column, **attributes)
      true
    end

    # Quoted chord symbols are consumed whole so a "%" inside quotes is
    # never mistaken for a comment.
    def scan_quoted_string(column)
      lexeme = @scanner.scan(/"[^"]*"/) || @scanner.scan(/"[^"]*/)
      lexeme && add_unsupported(lexeme, column)
    end

    def scan_bar_line(column)
      lexeme = @scanner.scan(BAR_LINE_PATTERN)
      return false unless lexeme

      add(:bar_line, column: column, style: NORMALIZED_BAR_STYLES.fetch(lexeme, lexeme))
      scan_trailing_volta
      true
    end

    # After a bar line, an immediately following digit begins a volta
    # (the "|1" / ":|2" shorthands for first and second endings).
    def scan_trailing_volta
      return unless @scanner.check(/\d/)

      column = @scanner.pos + 1
      add_volta(@scanner.scan(VOLTA_DIGITS_PATTERN), column)
    end

    def scan_bracket(column)
      return false unless @scanner.check(/\[/)
      return add_volta(@scanner[1], column) if @scanner.scan(/\[(\d[\d,-]*)/)

      inline_field = scan_first(INLINE_FIELD_PATTERNS)
      return add_unsupported(inline_field, column) if inline_field
      return scan_chord(column) if @scanner.check(ChordScanner::START_PATTERN)

      raise_unexpected_character(column)
    end

    def scan_chord(column)
      @tokens << ChordScanner.new(@scanner, @line_number, column).token
      true
    end

    def add_volta(digits, column)
      add(:volta, column: column, passes: VoltaPasses.parse(digits, @line_number))
    end

    def scan_note(column)
      return false unless @scanner.scan(NOTE_PATTERN)

      add(:note, column: column, accidental: @scanner[1], letter: @scanner[2], octave_marks: @scanner[3], length: @scanner[4])
    end

    def scan_rest(column)
      @scanner.scan(REST_PATTERN) && add(:rest, column: column, length: @scanner[1])
    end

    # Doubled marks (">>", "<<") are valid ABC (double-dotted broken rhythm)
    # but out of scope, so they surface as unsupported rather than as a
    # malformed-input error.
    def scan_broken_rhythm(column)
      doubled = @scanner.scan(/[<>]{2,}/)
      return add_unsupported(doubled, column) if doubled

      lexeme = @scanner.scan(/[<>]/)
      lexeme && add(:broken_rhythm, column: column, direction: lexeme.to_sym)
    end

    # A tie (a hyphen following a note or chord) joins it to the next
    # note of the same pitch; the parser fuses the two into one sounding
    # value. Ties inside a bracket chord still surface as unsupported via
    # the chord fallback.
    def scan_tie(column)
      @scanner.scan("-") && add(:tie, column: column)
    end

    def scan_slur(column)
      return add(:slur_start, column: column) if @scanner.scan(SLUR_START_PATTERN)

      @scanner.scan(")") && add(:slur_end, column: column)
    end

    def scan_decoration(column)
      lexeme = scan_first(DECORATION_PATTERNS)
      lexeme && add(:decoration, column: column, lexeme: lexeme)
    end

    def scan_unsupported(column)
      lexeme = scan_first(UNSUPPORTED_PATTERNS)
      lexeme && add_unsupported(lexeme, column)
    end

    def add_unsupported(lexeme, column)
      add(:unsupported, column: column, lexeme: lexeme)
    end

    # Returns the first pattern's match, trying each in order.
    def scan_first(patterns)
      patterns.each do |pattern|
        lexeme = @scanner.scan(pattern)
        return lexeme if lexeme
      end
      nil
    end

    def raise_unexpected_character(column)
      raise ParseError.new(
        "Unexpected character #{@scanner.peek(1).inspect} at column #{column}",
        line_number: @line_number,
        snippet: @scanner.rest[0, BodyLexer::SNIPPET_LENGTH]
      )
    end
  end
end
