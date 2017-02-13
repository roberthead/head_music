# A Spelling is a pitch class with a letter and an accidental

class HeadMusic::Spelling
  attr_reader :letter
  attr_reader :accidental
  attr_reader :pitch_class

  SPELLING_MATCHER = /([A-G])([b#]*)(\-?\d+)?/

  def self.get(identifier)
    @spellings ||= {}
    @spellings[identifier] ||= from_name(identifier) || from_number(identifier)
  end

  def self.from_name(name)
    return nil unless name == name.to_s
    match = name.match(SPELLING_MATCHER)
    if match
      letter_name, accidental_string, _octave = match.captures
      letter = HeadMusic::Letter.get(letter_name)
      if letter
        return new(letter, HeadMusic::Accidental.get(accidental_string))
      end
    end
  end

  def self.from_number(number)
    return nil unless number == number.to_i
    pitch_class_number = number % 12
    letter = HeadMusic::Letter.from_pitch_class(pitch_class_number)
    if letter.pitch_class != pitch_class_number
      accidental = HeadMusic::Accidental.for_interval(pitch_class_number - letter.pitch_class.to_i)
    end
    new(letter, accidental)
  end

  def initialize(letter, accidental = nil)
    @letter = HeadMusic::Letter.get(letter.to_s)
    @accidental = HeadMusic::Accidental.get(accidental.to_s)
    accidental_semitones = @accidental ? @accidental.semitones : 0
    @pitch_class = HeadMusic::PitchClass.get(letter.pitch_class + accidental_semitones)
  end

  def name
    [letter, accidental].join
  end

  def to_s
    name
  end

  def ==(value)
    to_s == value.to_s
  end

  private_class_method :new
end
