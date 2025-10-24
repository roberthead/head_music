class HeadMusic::Rudiment::Pitch::Parser
  attr_reader :identifier, :letter_name, :alteration, :register

  LetterName = HeadMusic::Rudiment::LetterName
  Alteration = HeadMusic::Rudiment::Alteration
  Spelling = HeadMusic::Rudiment::Spelling
  Register = HeadMusic::Rudiment::Register
  Pitch = HeadMusic::Rudiment::Pitch

  # Pattern that handles negative registers (e.g., -1) and positive registers
  # Anchored to match complete pitch strings only
  PATTERN = /\A(#{LetterName::PATTERN})?(#{Alteration::PATTERN.source})?(-?\d+)?\z/

  # Parse a pitch identifier and return a Pitch object
  # Returns nil if the identifier cannot be parsed into a valid pitch
  def self.parse(identifier)
    return nil if identifier.nil?
    new(identifier).pitch
  end

  def initialize(identifier)
    @identifier = identifier.to_s.strip
    parse_components
  end

  def pitch
    return unless spelling
    # Default to register 4 if not provided (matching old behavior)
    # Convert Register object to integer for fetch_or_create
    reg = register ? register.to_i : Register::DEFAULT

    @pitch ||= Pitch.fetch_or_create(spelling, reg)
  end

  def spelling
    return unless letter_name

    @spelling ||= Spelling.new(letter_name, alteration)
  end

  private

  def parse_components
    match = identifier.match(PATTERN)

    if match
      @letter_name = LetterName.get(match[1].upcase) unless match[1].to_s.empty?
      @alteration = Alteration.get(match[2] || "") unless match[2].to_s.empty?
      @register = Register.get(match[3]&.to_i) unless match[3].to_s.empty?
    end
  end
end
