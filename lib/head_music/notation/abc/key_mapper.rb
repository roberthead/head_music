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

  # MODE_NAMES_BY_PREFIX is many-to-one, so rendering uses this explicit
  # inverse map. Every suffix here parses back to an equal key signature
  # (ionian/aeolian differ from major/minor only in name, not alterations).
  ABC_SUFFIXES_BY_MODE = {
    "major" => "",
    "ionian" => "",
    "minor" => "m",
    "aeolian" => "m",
    "dorian" => "dor",
    "phrygian" => "phr",
    "lydian" => "lyd",
    "mixolydian" => "mix",
    "locrian" => "loc"
  }.freeze

  # Returns the ABC K: field value for a key signature.
  def self.abc_value(key_signature)
    key_signature = HeadMusic::Rudiment::KeySignature.get(key_signature)
    "#{tonic_string(key_signature)}#{mode_suffix(key_signature)}"
  end

  def self.tonic_string(key_signature)
    spelling = key_signature.tonic_spelling
    alteration = spelling.alteration
    if alteration && (alteration.double_sharp? || alteration.double_flat?)
      raise_render_error("Cannot render double-altered tonic #{spelling} in an ABC K: field")
    end

    # ABC convention uses ASCII "#"/"b" rather than the unicode signs
    # that Spelling#to_s produces.
    "#{spelling.letter_name}#{alteration&.ascii}"
  end
  private_class_method :tonic_string

  def self.mode_suffix(key_signature)
    ABC_SUFFIXES_BY_MODE[key_signature.scale_type.name.to_s] ||
      raise_render_error("Cannot render scale type #{key_signature.scale_type} in an ABC K: field")
  end
  private_class_method :mode_suffix

  def self.raise_render_error(message)
    raise HeadMusic::Notation::ABC::RenderError, message
  end
  private_class_method :raise_render_error

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
