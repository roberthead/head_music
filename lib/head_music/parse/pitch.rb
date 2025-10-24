module HeadMusic::Parse; end

# Backward compatibility wrapper that maintains lenient parsing behavior
# Unlike the strict Pitch::Parser, this can extract pitches from strings with additional content
class HeadMusic::Parse::Pitch
  attr_reader :identifier, :letter_name, :alteration, :register

  LetterName = HeadMusic::Rudiment::LetterName
  Alteration = HeadMusic::Rudiment::Alteration
  Spelling = HeadMusic::Rudiment::Spelling
  Register = HeadMusic::Rudiment::Register
  Pitch = HeadMusic::Rudiment::Pitch

  # Non-anchored pattern to extract pitch from beginning of string
  PATTERN = /(#{LetterName::PATTERN})?(#{Alteration::PATTERN.source})?(#{Register::PATTERN})?/

  def initialize(identifier)
    warn "[DEPRECATION] `HeadMusic::Parse::Pitch` is deprecated. " \
         "Use `HeadMusic::Rudiment::Pitch::Parser` for strict pitch parsing, " \
         "or `HeadMusic::Rudiment::Pitch.get` for general pitch retrieval.",
      uplevel: 1
    @identifier = identifier.to_s.strip
    parse
  end

  def pitch
    return unless spelling && register

    @pitch ||= Pitch.fetch_or_create(spelling, register.to_i)
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
