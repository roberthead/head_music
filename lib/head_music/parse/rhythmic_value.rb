module HeadMusic::Parse; end

# Backward compatibility wrapper for the new RhythmicValue::Parser
# Delegates to HeadMusic::Rudiment::RhythmicValue::Parser
class HeadMusic::Parse::RhythmicValue
  attr_reader :identifier, :rhythmic_value

  def initialize(identifier)
    warn "[DEPRECATION] `HeadMusic::Parse::RhythmicValue` is deprecated. " \
         "Use `HeadMusic::Rudiment::RhythmicValue::Parser` for parsing, " \
         "or `HeadMusic::Rudiment::RhythmicValue.get` for general retrieval.",
      uplevel: 1
    @identifier = identifier.to_s.strip
    @rhythmic_value = HeadMusic::Rudiment::RhythmicValue::Parser.parse(identifier)
  end
end
