# Converts an ABC K: field value into a key signature.
#
# ABC key values like "Ador" or "F#m" cannot be passed directly to
# KeySignature.get, which splits tonic and scale type on whitespace,
# so the mode word is normalized into a "tonic mode" string first.
class HeadMusic::Notation::ABC::KeyMapper
  KEY_PATTERN = /\A([A-G])([#♯b♭]?)\s*([A-Za-z]*)/

  # Mode words are matched case-insensitively on their first three letters,
  # so abbreviations ("dor") and full names ("Dorian") both resolve.
  MODE_NAMES_BY_PREFIX = {
    "maj" => "major",
    "ion" => "major",
    "min" => "minor",
    "aeo" => "minor",
    "dor" => "dorian",
    "phr" => "phrygian",
    "lyd" => "lydian",
    "mix" => "mixolydian",
    "loc" => "locrian"
  }.freeze

  attr_reader :value, :line_number

  def initialize(value, line_number: nil)
    @value = value.to_s.strip
    @line_number = line_number
  end

  def key_signature_name
    "#{tonic} #{mode_name}"
  end

  def key_signature
    HeadMusic::Rudiment::KeySignature.get(key_signature_name)
  end

  private

  def match
    @match ||= KEY_PATTERN.match(value) ||
      raise_parse_error("Unrecognized key")
  end

  def tonic
    match[1] + match[2]
  end

  def mode_name
    word = match[3].downcase
    return "major" if word.empty?
    return "minor" if word == "m"

    MODE_NAMES_BY_PREFIX[word[0, 3]] ||
      raise_parse_error("Unrecognized mode")
  end

  def raise_parse_error(message)
    raise HeadMusic::Notation::ABC::ParseError.new(
      "#{message} in K: field value #{value.inspect}",
      line_number: line_number,
      snippet: value
    )
  end
end
