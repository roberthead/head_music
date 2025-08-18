RhythmicValue = HeadMusic::Rudiment::RhythmicValue

class RhythmicValue::Parser
  attr_reader :identifier, :rhythmic_value

  def initialize(identifier)
    @identifier = identifier.to_s.strip
    parse
  end

  private

  def parse
    match = identifier.match(RhythmicValue::PATTERN)
    if match
      @rhythmic_value = RhythmicValue.get(match[0].to_s.strip)
    end
  end
end
