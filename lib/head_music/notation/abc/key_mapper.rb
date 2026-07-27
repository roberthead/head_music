# Converts an ABC K: field value into a key signature.
#
# ABC key values like "Ador" or "F#m" cannot be passed directly to
# KeySignature.get, which splits tonic and scale type on whitespace,
# so the mode word is normalized into a "tonic mode" string first.
class HeadMusic::Notation::ABC::KeyMapper
  # The alteration group wraps the pattern in (?:...) before making it optional.
  # Writing (...)? instead leaves match[2] nil for every unaltered key ("C", "Ador"),
  # which raises downstream where the capture is interpolated into a string.
  KEY_PATTERN = /\A([A-G])((?:#{HeadMusic::Rudiment::Alteration::PATTERN.source})?)\s*([A-Za-z]*)/

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

    # ABC convention uses ASCII "#"/"b" rather than the unicode signs that
    # Spelling#to_s produces. The double-altered guard above runs first, since this
    # would otherwise happily emit "Cx".
    #
    # A natural sign is dropped rather than converted. Accidentals.to_ascii preserves
    # "♮" on purpose — mapping it away would turn the spelling "C♮" into the different
    # spelling "C" — but an ABC K: field has no way to express a natural tonic, and
    # "C♮ major" names the same key signature as "C major".
    HeadMusic::Utilities::Accidentals.to_ascii(spelling.to_s).delete("♮")
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

  # An ABC K: field cannot express a double-altered tonic, and .abc_value raises
  # rather than rendering one. Reject it on the way in too: KEY_PATTERN interpolates
  # the whole Alteration::PATTERN so that "bb" and "##" bind correctly, which also
  # makes them matchable here. Without this guard "K:Cx" would parse to C𝄪 major and
  # report "no sharps or flats" — a plausible-looking wrong answer where the narrower
  # pattern used to give a clear parse error.
  def tonic
    alteration = HeadMusic::Rudiment::Alteration.get(match[2])
    if alteration && (alteration.double_sharp? || alteration.double_flat?)
      raise_parse_error("Cannot express double-altered tonic #{match[1]}#{match[2]} in an ABC K: field")
    end

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
