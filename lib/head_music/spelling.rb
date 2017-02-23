# A Spelling is a pitch class with a letter name and possibly an accidental
class HeadMusic::Spelling
  MATCHER = /^\s*([A-G])([b#]*)(\-?\d+)?\s*$/

  attr_reader :pitch_class
  attr_reader :letter
  attr_reader :accidental

  delegate :number, to: :pitch_class, prefix: true
  delegate :to_i, to: :pitch_class_number
  delegate :cycle, to: :letter, prefix: true
  delegate :enharmonic?, to: :pitch_class

  def self.get(identifier)
    from_name(identifier) || from_number(identifier)
  end
  singleton_class.send(:alias_method, :[], :get)

  def self.match(string)
    string.to_s.match(MATCHER)
  end

  def self.from_name(name)
    if match(name)
      letter_name, accidental_string, _octave = match(name).captures
      letter = HeadMusic::LetterName.get(letter_name)
      return nil unless letter
      accidental = HeadMusic::Accidental.get(accidental_string)
      fetch_or_create(letter, accidental)
    end
  end

  def self.from_number(number)
    return nil unless number == number.to_i
    pitch_class_number = number.to_i % 12
    letter = HeadMusic::LetterName.from_pitch_class(pitch_class_number)
    from_number_and_letter(number, letter)
  end

  def self.from_number_and_letter(number, letter)
    letter = HeadMusic::LetterName.get(letter)
    natural_letter_pitch_class = HeadMusic::LetterName.get(letter).pitch_class
    accidental_interval = letter.pitch_class.smallest_interval_to(HeadMusic::PitchClass.get(number))
    accidental = HeadMusic::Accidental.for_interval(accidental_interval)
    fetch_or_create(letter, accidental)
  end

  def self.fetch_or_create(letter, accidental)
    @spellings ||= {}
    key = [letter, accidental].join
    @spellings[key] ||= new(letter, accidental)
  end

  def initialize(letter, accidental = nil)
    @letter = HeadMusic::LetterName.get(letter.to_s)
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

  def sharp?
    accidental && accidental == '#'
  end

  def flat?
    accidental && accidental == 'b'
  end

  def ==(value)
    to_s == value.to_s
  end

  def scale(scale_type_name = nil)
    HeadMusic::Scale.get(self, scale_type_name)
  end

  private_class_method :new
end
