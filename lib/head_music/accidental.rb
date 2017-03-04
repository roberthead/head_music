class HeadMusic::Accidental
  ACCIDENTAL_SEMITONES = {
    '#' => 1,
    '##' => 2,
    'b' => -1,
    'bb' => -2
  }

  attr_reader :string

  def self.get(identifier)
    for_symbol(identifier) || for_interval(identifier)
  end

  def self.for_symbol(identifier)
    @accidentals ||= {}
    @accidentals[identifier.to_s] ||= new(identifier.to_s) if ACCIDENTAL_SEMITONES.keys.include?(identifier.to_s)
  end

  def self.for_interval(semitones)
    @accidentals ||= {}
    @accidentals[semitones.to_i] ||= ACCIDENTAL_SEMITONES.key(semitones.to_i)
  end

  def initialize(string)
    @string = string
  end

  def to_s
    string
  end

  def ==(value)
    to_s == value.to_s
  end

  def semitones
    ACCIDENTAL_SEMITONES.fetch(string, 0)
  end

  private_class_method :new
end
