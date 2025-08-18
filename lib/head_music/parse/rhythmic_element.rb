module HeadMusic::Parse; end

class HeadMusic::Parse::RhythmicElement
  attr_reader :identifier, :rhythmic_value

  delegate :letter_name, :alteration, :register, :spelling, :pitch, to: :pitch_parser
  delegate :rhythmic_value, to: :rhythmic_value_parser

  def initialize(identifier)
    @identifier = identifier.to_s.strip
  end

  def parsed_element
    if rhythmic_value
      if pitch
        HeadMusic::Rudiment::Note.new(pitch, rhythmic_value)
      else
        HeadMusic::Rudiment::Rest.new(rhythmic_value)
      end
    end
  end

  private

  def pitch_parser
    @pitch_parser ||= HeadMusic::Parse::Pitch.new(identifier)
  end

  def rhythmic_value_parser
    @rhythmic_value_parser ||= HeadMusic::Parse::RhythmicValue.new(identifier)
  end
end
