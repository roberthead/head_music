module HeadMusic::Parse; end

class HeadMusic::Parse::RhythmicValue
  attr_reader :identifier, :rhythmic_value

  PATTERN = /((double|triple)\W?)?(dotted)?.?(#{HeadMusic::Rudiment::RhythmicUnit::PATTERN})/

  def initialize(identifier)
    @identifier = identifier.to_s.strip
    parse
  end

  private

  def parse
    match = identifier.match(PATTERN)
    if match
      @rhythmic_value = HeadMusic::Rudiment::RhythmicValue.get(match[0].to_s.strip)
    end
  end
end
