module HeadMusic::Parse; end

class HeadMusic::Parse::RhythmicValue
  attr_reader :identifier, :rhythmic_value

  PATTERN = /((double|triple)\W?)?(dotted)?.?(#{HeadMusic::Rudiment::RhythmicUnit::PATTERN})/

  # For stuff like the "q." in "q. = 108"
  SHORTHAND_PATTERN = /\A(#{HeadMusic::Rudiment::RhythmicUnit::Parser::TEMPO_SHORTHAND_PATTERN})(\.*)?\z/i

  def initialize(identifier)
    @identifier = identifier.to_s.strip
    parse
  end

  private

  def parse
    # First check for shorthand patterns like "q." to avoid infinite recursion
    match = identifier.match(HeadMusic::Parse::RhythmicValue::SHORTHAND_PATTERN)
    if match && match[1]
      unit_name = HeadMusic::Rudiment::RhythmicUnit::Parser.parse(match[1].to_s.strip)
      dots = match[2] ? match[2].strip.length : 0
      @rhythmic_value = HeadMusic::Rudiment::RhythmicValue.new(unit_name, dots: dots) if unit_name
      return
    end

    # Then check the word pattern
    match = identifier.match(PATTERN)
    if match
      matched_string = match[0].to_s.strip
      # Extract unit and dots from the matched string
      unit_part = matched_string.gsub(/^\W*(double|triple)?\W*(dotted)?\W*/, "")
      unit = HeadMusic::Rudiment::RhythmicUnit.get(unit_part)
      if unit
        dots = if matched_string.include?("triple")
          3
        elsif matched_string.include?("double")
          2
        else
          matched_string.include?("dotted") ? 1 : 0
        end
        @rhythmic_value = HeadMusic::Rudiment::RhythmicValue.new(unit, dots: dots)
      end
    end
  end
end
