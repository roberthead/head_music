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
    return unless match

    @letter_name = parse_letter_name(match[1])
    @alteration = parse_alteration(match[2])
    @register = parse_register(match[3])
  end

  def parse_letter_name(token)
    LetterName.get(token.upcase) unless token.to_s.empty?
  end

  def parse_alteration(token)
    Alteration.get(token || "") unless token.to_s.empty?
  end

  def parse_register(token)
    Register.get(token.to_i) unless token.to_s.empty?
  end
end
