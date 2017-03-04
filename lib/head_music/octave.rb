class HeadMusic::Octave
  include Comparable

  DEFAULT = 4

  MATCHER = /(-?\d+)$/

  def self.get(identifier)
    from_number(identifier) || from_name(identifier) || default
  end

  def self.from_number(identifier)
    return nil unless identifier.to_s == identifier.to_i.to_s
    return nil unless (-2..12).include?(identifier.to_i)
    @octaves ||= {}
    @octaves[identifier.to_i] ||= new(identifier.to_i)
  end

  def self.from_name(string)
    if string.to_s.match(HeadMusic::Spelling::MATCHER)
      _letter, _accidental, octave_string = string.to_s.match(HeadMusic::Spelling::MATCHER).captures
      @octaves ||= {}
      @octaves[octave_string.to_i] ||= new(octave_string.to_i) if octave_string
    end
  end

  def self.default
    @octaves[DEFAULT] ||= new(DEFAULT)
  end

  attr_reader :number
  delegate :to_i, :to_s, to: :number

  def initialize(number)
    @number ||= number
  end

  def <=>(other)
    self.to_i <=> other.to_i
  end

  private_class_method :new
end
