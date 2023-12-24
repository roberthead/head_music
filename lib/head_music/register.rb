# The register is a numeric octave identifier used in scientific pitch notation.
#
# A pitch is a spelling plus a register. For example, C4 is middle C and C5 is the C one octave higher.
# The number changes between the letter names B and C regardless of sharps and flats,
# so as an extreme example, Cb5 is actually a semitone below B#4.
class HeadMusic::Register
  include Comparable

  DEFAULT = 4

  def self.get(identifier)
    from_number(identifier) || from_name(identifier) || default
  end

  def self.from_number(identifier)
    return nil unless identifier.to_s == identifier.to_i.to_s
    return nil unless (-2..12).cover?(identifier.to_i)

    @registers ||= {}
    @registers[identifier.to_i] ||= new(identifier.to_i)
  end

  def self.from_name(string)
    return unless string.to_s.match?(HeadMusic::Spelling::MATCHER)

    _letter, _sign, register_string = string.to_s.match(HeadMusic::Spelling::MATCHER).captures
    @registers ||= {}
    @registers[register_string.to_i] ||= new(register_string.to_i) if register_string
  end

  def self.default
    @registers[DEFAULT] ||= new(DEFAULT)
  end

  attr_reader :number

  delegate :to_i, :to_s, to: :number

  def initialize(number)
    @number = number
  end

  def <=>(other)
    to_i <=> other.to_i
  end

  def +(other)
    self.class.get(to_i + other.to_i)
  end

  def -(other)
    self.class.get(to_i - other.to_i)
  end

  def helmholtz_case
    return :upper if number < 3

    :lower
  end

  def helmholtz_marks
    return "," * (2 - number) if number < 2
    return "'" * (number - 3) if number > 3

    ""
  end

  private_class_method :new
end
