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
    # First check for shorthand patterns like "q." to avoid infinite recursion
    match = identifier.match(SHORTHAND_PATTERN)
    if match && match[1]
      unit_name = RhythmicUnit::Parser.parse(match[1].to_s.strip)
      dots = match[2] ? match[2].strip.length : 0
      @rhythmic_value = RhythmicValue.new(unit_name, dots: dots) if unit_name
      return
    end

    # Try RhythmicUnit::Parser directly first (handles fractions, decimals, British names, etc.)
    parser = RhythmicUnit::Parser.new(identifier)
    if parser.american_name
      @rhythmic_value = RhythmicValue.new(parser.american_name, dots: 0)
      return
    end

    # Then try to parse with dots extracted for formats like "1/4."
    # Count and strip dots (e.g., "1/4." -> "1/4" with 1 dot)
    # But skip this if identifier looks like a decimal number
    unless identifier.match?(/^\d+\.\d+$/)
      dots = identifier.scan(".").count
      base_identifier = identifier.gsub(".", "").strip

      # Try RhythmicUnit::Parser on the base identifier
      parser = RhythmicUnit::Parser.new(base_identifier)
      if parser.american_name
        @rhythmic_value = RhythmicValue.new(parser.american_name, dots: dots)
        return
      end
    end

    # Finally check the word pattern for things like "dotted quarter"
    match = identifier.match(PATTERN)
    if match
      matched_string = match[0].to_s.strip
      # Extract unit and dots from the matched string
      unit_part = matched_string.gsub(/^\W*(double|triple)?\W*(dotted)?\W*/, "")
      unit = RhythmicUnit.get(unit_part)
      if unit
        dots = if matched_string.include?("triple")
          3
        elsif matched_string.include?("double")
          2
        else
          matched_string.include?("dotted") ? 1 : 0
        end
        @rhythmic_value = RhythmicValue.new(unit, dots: dots)
      end
    end
  end
end
