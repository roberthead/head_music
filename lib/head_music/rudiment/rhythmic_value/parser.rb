class HeadMusic::Rudiment::RhythmicValue::Parser
  attr_reader :identifier, :rhythmic_value

  RhythmicUnit = HeadMusic::Rudiment::RhythmicUnit
  RhythmicValue = HeadMusic::Rudiment::RhythmicValue

  PATTERN = /((double|triple)\W?)?(dotted)?.?(#{HeadMusic::Rudiment::RhythmicUnit::PATTERN})/

  # For stuff like the "q." in "q. = 108"
  SHORTHAND_PATTERN = /\A(#{HeadMusic::Rudiment::RhythmicUnit::Parser::TEMPO_SHORTHAND_PATTERN})(\.*)?\z/i

  # Parse a rhythmic value identifier and return a RhythmicValue object
  # Returns nil if the identifier cannot be parsed
  def self.parse(identifier)
    return nil if identifier.nil?
    new(identifier).rhythmic_value
  end

  def initialize(identifier)
    @identifier = identifier.to_s.strip
    parse_components
  end

  private

  def parse_components
    @rhythmic_value =
      from_shorthand ||
      from_direct_unit ||
      from_dotted_unit ||
      from_word_pattern
  end

  # Check for shorthand patterns like "q." first to avoid infinite recursion
  def from_shorthand
    match = identifier.match(SHORTHAND_PATTERN)
    return nil unless match && match[1]

    unit_name = RhythmicUnit::Parser.parse(match[1].to_s.strip)
    return nil unless unit_name

    dots = match[2] ? match[2].strip.length : 0
    RhythmicValue.new(unit_name, dots: dots)
  end

  # Try RhythmicUnit::Parser directly (handles fractions, decimals, British names, etc.)
  def from_direct_unit
    parser = RhythmicUnit::Parser.new(identifier)
    return nil unless parser.american_name

    RhythmicValue.new(parser.american_name, dots: 0)
  end

  # Parse with dots extracted for formats like "1/4." (-> "1/4" with 1 dot),
  # skipping identifiers that look like a decimal number.
  def from_dotted_unit
    return nil if identifier.match?(/^\d+\.\d+$/)

    dots = identifier.scan(".").count
    parser = RhythmicUnit::Parser.new(identifier.delete(".").strip)
    return nil unless parser.american_name

    RhythmicValue.new(parser.american_name, dots: dots)
  end

  # Check the word pattern for things like "dotted quarter"
  def from_word_pattern
    match = identifier.match(PATTERN)
    return nil unless match

    matched_string = match[0].to_s.strip
    unit = RhythmicUnit.get(matched_string.gsub(/^\W*(double|triple)?\W*(dotted)?\W*/, ""))
    return nil unless unit

    RhythmicValue.new(unit, dots: dots_from_word(matched_string))
  end

  def dots_from_word(matched_string)
    return 3 if matched_string.include?("triple")
    return 2 if matched_string.include?("double")

    matched_string.include?("dotted") ? 1 : 0
  end
end
