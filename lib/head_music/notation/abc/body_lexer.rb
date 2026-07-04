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
    :style, :passes, :direction, :voice_id, :lexeme
  ) do
    def initialize(
      type:, line:, column:,
      letter: nil, accidental: nil, octave_marks: nil, length: nil,
      style: nil, passes: nil, direction: nil, voice_id: nil, lexeme: nil
    )
      super
    end
  end

  # Alternatives are ordered longest-first so the scanner never takes a
  # short match when a longer bar line is present (e.g. "|]" before "|").
  BAR_LINE_PATTERN = /:\|\|:|:\|:|::|:\||\|:|\|\||\|\]|\[\||\|/

  # ":||:" and ":|:" are alternate spellings of the double repeat "::".
  NORMALIZED_BAR_STYLES = {":||:" => "::", ":|:" => "::"}.freeze

  NOTE_PATTERN = %r{(\^\^|\^|__|_|=)?([A-Ga-g])([',]*)([\d/]*)}
  REST_PATTERN = %r{z([\d/]*)}
  VOLTA_DIGITS_PATTERN = /\d[\d,-]*/

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

      line_number = @start_line + index
      if !continued && line_start_token(line_text, line_number, tokens)
        next
      end
      continued = scan_line(line_text, line_number, tokens)
    end
    tokens
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

  # Returns true when the line ends with a continuation backslash.
  def scan_line(line_text, line_number, tokens)
    scanner = StringScanner.new(line_text)
    until scanner.eos?
      next if scanner.skip(/[ \t]+/)
      break if scanner.skip(/%/)
      return true if scanner.skip(/\\[ \t]*\z/)

      scan_token(scanner, line_number, tokens)
    end
    false
  end

  def scan_token(scanner, line_number, tokens)
    column = scanner.pos + 1

    return if scan_quoted_string(scanner, line_number, column, tokens)
    return if scan_bar_line(scanner, line_number, column, tokens)
    return if scan_bracket(scanner, line_number, column, tokens)
    return if scan_note(scanner, line_number, column, tokens)
    return if scan_rest(scanner, line_number, column, tokens)
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

    inline_field = scanner.scan(/\[[A-Za-z]:[^\]]*\]/) || scanner.scan(/\[[A-Za-z]:[^\]]*/)
    if inline_field
      tokens << unsupported_token(inline_field, line_number, column)
      return true
    end

    if scanner.check(/\[[A-Ga-g]/)
      chord = scanner.scan(/\[[^\]]*\]/) || scanner.scan(/\[[^\]]*/)
      tokens << unsupported_token(chord, line_number, column)
      return true
    end

    raise_unexpected_character(scanner, line_number, column)
  end

  def volta_token(digits, line_number, column)
    Token.new(type: :volta, line: line_number, column: column, passes: volta_passes(digits))
  end

  def volta_passes(digits)
    digits.split(",").flat_map do |part|
      first, last = part.split("-", 2)
      last ? (first.to_i..last.to_i).to_a : [first.to_i]
    end.select(&:positive?)
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
    lexeme = scanner.scan(/[<>]/)
    return false unless lexeme

    tokens << Token.new(
      type: :broken_rhythm, line: line_number, column: column, direction: lexeme.to_sym
    )
    true
  end

  # Recognizable ABC we deliberately don't handle: grace notes,
  # decorations, tuplets, slurs, ties, and special rests.
  def scan_unsupported(scanner, line_number, column, tokens)
    lexeme =
      scanner.scan(/\{[^}]*\}/) || scanner.scan(/\{[^}]*/) ||
      scanner.scan(/![^!]*!/) || scanner.scan(/![^!]*/) ||
      scanner.scan(/\(\d/) || scanner.scan(/[()\-~.]/) ||
      scanner.scan(/Z\d*/) || scanner.scan(%r{x[\d/]*})
    return false unless lexeme

    tokens << unsupported_token(lexeme, line_number, column)
    true
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
