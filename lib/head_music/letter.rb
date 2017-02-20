class HeadMusic::Letter
  # Defines the natural relationship between the natural letter-named notes

  NAMES = ('A'..'G').to_a

  NATURAL_PITCH_CLASS_NUMBERS = {
    'C' => 0,
    'D' => 2,
    'E' => 4,
    'F' => 5,
    'G' => 7,
    'A' => 9,
    'B' => 11,
  }

  def self.all
    NAMES.map { |letter_name| get(letter_name)}
  end

  def self.get(identifier)
    from_name(identifier) || from_pitch_class(identifier)
  end

  def self.from_name(name)
    @letters ||= {}
    name = name.to_s.first.upcase
    @letters[name] ||= new(name) if NAMES.include?(name)
  end

  def self.from_pitch_class(pitch_class)
    @letters ||= {}
    return nil if pitch_class.to_s == pitch_class
    pitch_class = pitch_class.to_i % 12
    name = NAMES.detect { |name| pitch_class == NATURAL_PITCH_CLASS_NUMBERS[name] }
    name ||= HeadMusic::PitchClass::PREFERRED_SPELLINGS[pitch_class].first
    @letters[name] ||= new(name) if NAMES.include?(name)
  end

  attr_reader :name

  delegate :to_s, to: :name
  delegate :to_sym, to: :name
  delegate :to_i, to: :pitch_class

  def initialize(name)
    @name = name
  end

  def pitch_class
    HeadMusic::PitchClass.get(NATURAL_PITCH_CLASS_NUMBERS[name])
  end

  def ==(value)
    to_s == value.to_s
  end

  def cycle
    cycle = NAMES
    while cycle.first != self.to_s
      cycle = cycle.rotate
    end
    cycle
  end

  private_class_method :new
end
