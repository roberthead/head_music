require "strscan"

# Tokenizes the body of an ABC tune (the text after the K: header line).
#
# Emits flat value tokens rather than a tree so the parser can decide
# how much structure to build. Out-of-scope-but-valid ABC constructs are
# emitted as :unsupported tokens (instead of raising here) so the parser
# can raise UnsupportedFeatureError with knowledge of what it was.
class HeadMusic::Notation::ABC::BodyLexer
  # One struct type for all tokens keeps the parser's pattern matching
  # simple; fields that don't apply to a token type are nil.
  Token = Data.define(
    :type, :line, :column,
    :letter, :accidental, :octave_marks, :length,
    :style, :passes, :direction, :voice_id, :lexeme, :notes
  ) do
    def initialize(
      type:, line:, column:,
      letter: nil, accidental: nil, octave_marks: nil, length: nil,
      style: nil, passes: nil, direction: nil, voice_id: nil, lexeme: nil,
      notes: nil
    )
      super
    end
  end

  # One note inside a bracket chord. Each note may carry its own length;
  # the parser enforces that they are uniform and multiplies the shared
  # inner length with any outer length on the token (ABC 2.1 sec. 4.17).
  ChordNote = Data.define(:accidental, :letter, :octave_marks, :length)

  # Alternatives are ordered longest-first so the scanner never takes a
  # short match when a longer bar line is present (e.g. "|]" before "|").
  BAR_LINE_PATTERN = /:\|\|:|:\|:|::|:\||\|:|\|\||\|\]|\[\||\|/

  # ":||:" and ":|:" are alternate spellings of the double repeat "::".
  NORMALIZED_BAR_STYLES = {":||:" => "::", ":|:" => "::"}.freeze

  NOTE_PATTERN = %r{(\^\^|\^|__|_|=)?([A-Ga-g])([',]*)([\d/]*)}
  CHORD_START_PATTERN = /\[(\^\^|\^|__|_|=)?[A-Ga-g]/
  # An inline field ("[K:...]"), tried closed before its unterminated fallback.
  INLINE_FIELD_PATTERNS = [/\[[A-Za-z]:[^\]]*\]/, /\[[A-Za-z]:[^\]]*/].freeze
  CHORD_NOTE_PATTERN = %r{(\^\^|\^|__|_|=)?([A-Ga-g])([',]*)([\d/]*)}
  REST_PATTERN = %r{z([\d/]*)}
  VOLTA_DIGITS_PATTERN = /\d[\d,-]*/

  # Recognizable ABC we deliberately don't handle: grace notes ({..}),
  # decorations (!..!), tuplets, slurs, and special rests (Z, x). Ordered
  # so a closed form is tried before its unterminated fallback.
  UNSUPPORTED_PATTERNS = [
    /\{[^}]*\}/, /\{[^}]*/, /![^!]*!/, /![^!]*/,
    /\(\d/, /[()~.]/, /Z\d*/, %r{x[\d/]*}
  ].freeze

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

    raise HeadMusic::Notation::ABC::ParseError.new(
      "Tune body is not valid UTF-8", line_number: @start_line
    )
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

    scan_line(line_text, line_number, tokens)
  end

  # Handles lines that are fields rather than music: V: switches voices;
  # any other letter-colon line is a field we don't interpret in the body.
  def line_start_token(line_text, line_number, tokens)
    if line_text.start_with?("V:")
      tokens << voice_change_token(line_text, line_number)
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

  # Music tokens whose whitespace successor breaks a beam group; other
  # tokens (bar lines, ties, etc.) already interrupt beaming on their own.
  BEAMABLE_TOKEN_TYPES = [:note, :rest, :chord].freeze

  # Returns true when the line ends with a continuation backslash.
  def scan_line(line_text, line_number, tokens)
    scanner = StringScanner.new(line_text)
    until scanner.eos?
      spaced = scanner.skip(/[ \t]+/)
      break if scanner.skip(/%/)
      return true if scanner.skip(/\\[ \t]*\z/)
      break if scanner.eos?

      tokens << beam_break_token(scanner, line_number) if spaced && beamable_predecessor?(tokens.last)
      scan_token(scanner, line_number, tokens)
    end
    false
  end

  # A beam break only matters after a music token; whitespace elsewhere
  # (leading, after a bar line) carries no beaming signal.
  def beamable_predecessor?(token)
    !token.nil? && BEAMABLE_TOKEN_TYPES.include?(token.type)
  end

  def beam_break_token(scanner, line_number)
    Token.new(type: :beam_break, line: line_number, column: scanner.pos + 1)
  end

  def scan_token(scanner, line_number, tokens)
    column = scanner.pos + 1

    return if scan_quoted_string(scanner, line_number, column, tokens)
    return if scan_bar_line(scanner, line_number, column, tokens)
    return if scan_bracket(scanner, line_number, column, tokens)
    return if scan_note(scanner, line_number, column, tokens)
    return if scan_rest(scanner, line_number, column, tokens)
    return if scan_tie(scanner, line_number, column, tokens)
    return if scan_broken_rhythm(scanner, line_number, column, tokens)
    return if scan_unsupported(scanner, line_number, column, tokens)

    raise_unexpected_character(scanner, line_number, column)
  end

  # Quoted chord symbols are consumed whole so a "%" inside quotes is
  # never mistaken for a comment.
  def scan_quoted_string(scanner, line_number, column, tokens)
    lexeme = scanner.scan(/"[^"]*"/) || scanner.scan(/"[^"]*/)
    return false unless lexeme

    tokens << unsupported_token(lexeme, line_number, column)
    true
  end

  def scan_bar_line(scanner, line_number, column, tokens)
    lexeme = scanner.scan(BAR_LINE_PATTERN)
    return false unless lexeme

    style = NORMALIZED_BAR_STYLES.fetch(lexeme, lexeme)
    tokens << Token.new(type: :bar_line, line: line_number, column: column, style: style)
    scan_trailing_volta(scanner, line_number, tokens)
    true
  end

  # After a bar line, an immediately following digit begins a volta
  # (the "|1" / ":|2" shorthands for first and second endings).
  def scan_trailing_volta(scanner, line_number, tokens)
    return unless scanner.check(/\d/)

    column = scanner.pos + 1
    digits = scanner.scan(VOLTA_DIGITS_PATTERN)
    tokens << volta_token(digits, line_number, column)
  end

  def scan_bracket(scanner, line_number, column, tokens)
    return false unless scanner.check(/\[/)

    digits = scanner.scan(/\[(\d[\d,-]*)/)
    if digits
      tokens << volta_token(scanner[1], line_number, column)
      return true
    end

    inline_field = scan_first(scanner, INLINE_FIELD_PATTERNS)
    if inline_field
      tokens << unsupported_token(inline_field, line_number, column)
      return true
    end

    return scan_chord(scanner, line_number, column, tokens) if scanner.check(CHORD_START_PATTERN)

    raise_unexpected_character(scanner, line_number, column)
  end

  def scan_chord(scanner, line_number, column, tokens)
    start_pos = scanner.pos
    scanner.skip(/\[/)
    notes = collect_chord_notes(scanner)
    return chord_fallback(scanner, start_pos, line_number, column, tokens) unless notes

    length = scanner.scan(%r{[\d/]*})
    tokens << Token.new(type: :chord, line: line_number, column: column, notes: notes, length: length)
    true
  end

  # Collects the notes between the brackets, or nil when a non-note is hit
  # (leaving the scanner where it stopped so the fallback can react).
  def collect_chord_notes(scanner)
    notes = []
    until scanner.skip(/\]/)
      return nil unless scanner.scan(CHORD_NOTE_PATTERN)

      notes << ChordNote.new(
        accidental: scanner[1], letter: scanner[2],
        octave_marks: scanner[3], length: scanner[4]
      )
    end
    notes
  end

  # Non-note content inside the brackets (ties, rests, spaces,
  # decorations) makes the whole group one unsupported token, matching
  # how those constructs surface outside a chord.
  def chord_fallback(scanner, start_pos, line_number, column, tokens)
    if scanner.eos?
      raise HeadMusic::Notation::ABC::ParseError.new(
        'Unterminated chord; expected "]"',
        line_number: line_number, snippet: chord_snippet(scanner, start_pos)
      )
    end
    scanner.pos = start_pos
    lexeme = scanner.scan(/\[[^\]]*\]/) || scanner.scan(/\[[^\]]*/)
    tokens << unsupported_token(lexeme, line_number, column)
    true
  end

  def chord_snippet(scanner, start_pos)
    scanner.string[start_pos, SNIPPET_LENGTH]
  end

  def volta_token(digits, line_number, column)
    passes = volta_passes(digits)
    unless passes.uniq.length == passes.length
      raise HeadMusic::Notation::ABC::ParseError.new(
        "Volta passes must be unique",
        line_number: line_number, snippet: digits
      )
    end
    Token.new(type: :volta, line: line_number, column: column, passes: passes)
  end

  def volta_passes(digits)
    digits.split(",").flat_map { |part| expand_volta_range(part) }.select(&:positive?)
  end

  def expand_volta_range(part)
    first, last = part.split("-", 2)
    last ? (first.to_i..last.to_i).to_a : [first.to_i]
  end

  def scan_note(scanner, line_number, column, tokens)
    return false unless scanner.scan(NOTE_PATTERN)

    tokens << Token.new(
      type: :note, line: line_number, column: column,
      accidental: scanner[1], letter: scanner[2],
      octave_marks: scanner[3], length: scanner[4]
    )
    true
  end

  def scan_rest(scanner, line_number, column, tokens)
    return false unless scanner.scan(REST_PATTERN)

    tokens << Token.new(type: :rest, line: line_number, column: column, length: scanner[1])
    true
  end

  def scan_broken_rhythm(scanner, line_number, column, tokens)
    # Doubled marks (">>", "<<") are valid ABC (double-dotted broken
    # rhythm) but out of scope, so they surface as unsupported rather
    # than as a malformed-input error.
    doubled = scanner.scan(/[<>]{2,}/)
    if doubled
      tokens << unsupported_token(doubled, line_number, column)
      return true
    end

    lexeme = scanner.scan(/[<>]/)
    return false unless lexeme

    tokens << Token.new(
      type: :broken_rhythm, line: line_number, column: column, direction: lexeme.to_sym
    )
    true
  end

  # A tie (a hyphen following a note or chord) joins it to the next
  # note of the same pitch; the parser fuses the two into one sounding
  # value. Ties inside a bracket chord still surface as unsupported via
  # the chord fallback.
  def scan_tie(scanner, line_number, column, tokens)
    return false unless scanner.scan("-")

    tokens << Token.new(type: :tie, line: line_number, column: column)
    true
  end

  def scan_unsupported(scanner, line_number, column, tokens)
    lexeme = scan_first(scanner, UNSUPPORTED_PATTERNS)
    return false unless lexeme

    tokens << unsupported_token(lexeme, line_number, column)
    true
  end

  # Returns the first pattern's match, trying each in order.
  def scan_first(scanner, patterns)
    patterns.each do |pattern|
      lexeme = scanner.scan(pattern)
      return lexeme if lexeme
    end
    nil
  end

  def unsupported_token(lexeme, line_number, column)
    Token.new(type: :unsupported, line: line_number, column: column, lexeme: lexeme)
  end

  def raise_unexpected_character(scanner, line_number, column)
    character = scanner.peek(1)
    raise HeadMusic::Notation::ABC::ParseError.new(
      "Unexpected character #{character.inspect} at column #{column}",
      line_number: line_number,
      snippet: scanner.rest[0, SNIPPET_LENGTH]
    )
  end
end
