# Splits an ABC tune string into header fields and tune body.
#
# The K: (key) field is required and must be the last header field;
# everything after that line is the tune body. Requiring K: avoids
# silently defaulting the composition to C major.
class HeadMusic::Notation::ABC::Header
  FIELD_PATTERN = /\A([A-Za-z]):(.*)\z/
  FRACTION_PATTERN = %r{\A\d+/\d+\z}

  attr_reader :reference_number, :title, :composer, :origin,
    :annotations, :voice_ids, :meter, :key_signature,
    :body, :body_start_line

  # start_line offsets reported line numbers, so a tune parsed out of a
  # larger book raises errors with book-relative line numbers.
  def initialize(abc_string, start_line: 1)
    @annotations = []
    @voice_ids = []
    @start_line = start_line
    parse(abc_string)
  end

  def unit_note_length
    @unit_note_length || default_unit_note_length
  end

  private

  def parse(abc_string)
    lines = abc_string.to_s.lines
    lines.each_with_index do |raw_line, index|
      line_number = index + @start_line
      stripped = raw_line.strip
      next if stripped.empty? || stripped.start_with?("%")

      if assign_field(stripped, line_number)
        capture_body(lines, index)
        break
      end
    end
    raise_missing_key_error unless @key_signature
    apply_defaults
  end

  # Returns true when the field is K:, which terminates the header.
  def assign_field(stripped_line, line_number)
    letter, value = parse_field(stripped_line, line_number)
    return assign_key(value, line_number) if letter == "K"

    store_field(letter, value, line_number, stripped_line)
    false
  end

  def parse_field(stripped_line, line_number)
    match = FIELD_PATTERN.match(stripped_line)
    unless match
      raise HeadMusic::Notation::ABC::ParseError.new(
        "Expected a header field; the tune body may not begin before the K: (key) field",
        line_number: line_number, snippet: stripped_line
      )
    end
    [match[1], match[2].strip]
  end

  def assign_key(value, line_number)
    @key_signature = HeadMusic::Notation::ABC::KeyMapper.new(value, line_number: line_number).key_signature
    true
  end

  def store_field(letter, value, line_number, stripped_line)
    case letter
    when "X" then @reference_number = value
    when "T" then @title = value
    when "C" then @composer = value
    when "O" then @origin = value
    when "N" then @annotations << value
    when "M" then @meter = resolve_meter(value, line_number)
    when "L" then @unit_note_length = resolve_unit_note_length(value, line_number)
    when "V" then @voice_ids << value.split.first
    else
      raise HeadMusic::Notation::ABC::UnsupportedFeatureError.new(
        "Unsupported header field #{letter.inspect}", line_number: line_number, snippet: stripped_line
      )
    end
  end

  def capture_body(lines, key_line_index)
    @body = lines[(key_line_index + 1)..].join
    @body_start_line = key_line_index + 1 + @start_line
  end

  def resolve_meter(value, line_number)
    # "C" and "C|" must be translated before calling Meter.get, which
    # memoizes by identifier and would cache a meaningless "C" meter.
    return HeadMusic::Rudiment::Meter.common_time if value == "C"
    return HeadMusic::Rudiment::Meter.cut_time if value == "C|"

    ensure_fraction!(value, "meter", line_number)
    HeadMusic::Rudiment::Meter.get(value)
  end

  def resolve_unit_note_length(value, line_number)
    ensure_fraction!(value, "unit note length", line_number)
    Rational(value)
  end

  def ensure_fraction!(value, description, line_number)
    return if FRACTION_PATTERN.match?(value)

    raise HeadMusic::Notation::ABC::ParseError.new(
      "Invalid #{description} #{value.inspect}", line_number: line_number, snippet: value
    )
  end

  def apply_defaults
    @meter ||= HeadMusic::Rudiment::Meter.common_time
  end

  # ABC 2.1 default: when L: is absent, meters smaller than 3/4
  # imply sixteenth notes; 3/4 and larger imply eighth notes.
  def default_unit_note_length
    meter_fraction = Rational(meter.top_number, meter.bottom_number)
    (meter_fraction < Rational(3, 4)) ? Rational(1, 16) : Rational(1, 8)
  end

  def raise_missing_key_error
    raise HeadMusic::Notation::ABC::ParseError,
      "Missing required K: (key) field"
  end
end
