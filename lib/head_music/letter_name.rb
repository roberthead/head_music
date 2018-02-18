class HeadMusic::LetterName
  NAMES = %w[C D E F G A B]

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
    @letter_names ||= {}
    name = name.to_s.first.upcase
    @letter_names[name] ||= new(name) if NAMES.include?(name)
  end

  def self.from_pitch_class(pitch_class)
    @letter_names ||= {}
    return nil if pitch_class.to_s == pitch_class
    pitch_class = pitch_class.to_i % 12
    name = NAMES.detect { |candidate| pitch_class == NATURAL_PITCH_CLASS_NUMBERS[candidate] }
    name ||= HeadMusic::PitchClass::SHARP_SPELLINGS[pitch_class].first
    @letter_names[name] ||= new(name) if NAMES.include?(name)
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

  def ==(other)
    to_s == other.to_s
  end

  def position
    NAMES.index(self.to_s) + 1
  end

  def steps(num)
    HeadMusic::LetterName.get(cycle[num % NAMES.length])
  end

  def steps_to(other, direction = :ascending)
    other = HeadMusic::LetterName.get(other)
    other_position = other.position
    if direction == :descending
      other_position -= NAMES.length if other_position > position
      position - other_position
    else
      other_position += NAMES.length if other_position < position
      other_position - position
    end
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
