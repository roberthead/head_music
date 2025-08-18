class HeadMusic::Rudiment::Pitch::Parser
  attr_reader :identifier, :letter_name, :alteration, :register, :rhythmic_value

  LetterName = HeadMusic::Rudiment::LetterName
  Alteration = HeadMusic::Rudiment::Alteration
  Spelling = HeadMusic::Rudiment::Spelling
  Register = HeadMusic::Rudiment::Register
  Pitch = HeadMusic::Rudiment::Pitch

  PATTERN = /(#{LetterName::PATTERN})?(#{Alteration::PATTERN.source})?(#{Register::PATTERN})?/

  def initialize(identifier)
    @identifier = identifier.to_s.strip
    parse
  end

  def pitch
    return unless spelling && register

    @pitch ||= Pitch.new(spelling, register)
  end

  def spelling
    return unless letter_name

    @spelling ||= Spelling.new(letter_name, alteration)
  end

  private

  def parse
    match = identifier.match(PATTERN)

    if match
      @letter_name = LetterName.get(match[1].upcase) unless match[1].to_s.empty?
      @alteration = Alteration.get(match[2] || "") unless match[2].to_s.empty?
      @register = Register.get(match[3]&.to_i) unless match[3].to_s.empty?
    end
  end
end
