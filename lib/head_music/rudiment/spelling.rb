# A module for music rudiments
module HeadMusic::Rudiment; end

# Represents the spelling of a pitch, such as C# or Db.
# Composite of a LetterName and an optional Alteration.
# Does not include the octave. See Pitch for that.
class HeadMusic::Rudiment::Spelling
  MATCHER = /^\s*([A-G])(#{HeadMusic::Rudiment::Alteration::PATTERN}?)(-?\d+)?\s*$/i

  attr_reader :pitch_class, :letter_name, :alteration

  delegate :number, to: :pitch_class, prefix: true
  delegate :to_i, to: :pitch_class_number
  delegate :series_ascending, :series_descending, to: :letter_name, prefix: true
  delegate :enharmonic?, to: :enharmonic_equivalence
  delegate :sharp?, :flat?, :double_sharp?, :double_flat?, to: :alteration, allow_nil: true

  def self.get(identifier)
    return identifier if identifier.is_a?(HeadMusic::Rudiment::Spelling)

    from_name(identifier) || from_number(identifier)
  end

  def self.matching_string(string)
    string.to_s.match(MATCHER)
  end

  def self.from_name(name)
    return nil unless matching_string(name)

    letter_name, sign_string, _octave = matching_string(name).captures
    letter_name = HeadMusic::Rudiment::LetterName.get(letter_name)
    return nil unless letter_name

    alteration = HeadMusic::Rudiment::Alteration.get(sign_string)
    fetch_or_create(letter_name, alteration)
  end

  def self.from_number(number)
    return nil unless number == number.to_i

    pitch_class_number = number.to_i % 12
    letter_name = HeadMusic::Rudiment::LetterName.from_pitch_class(pitch_class_number)
    from_number_and_letter(number, letter_name)
  end

  def self.from_number_and_letter(number, letter_name)
    letter_name = HeadMusic::Rudiment::LetterName.get(letter_name)
    natural_letter_pitch_class = letter_name.pitch_class
    alteration_interval = natural_letter_pitch_class.smallest_interval_to(HeadMusic::Rudiment::PitchClass.get(number))
    alteration = HeadMusic::Rudiment::Alteration.by(:semitones, alteration_interval) if alteration_interval != 0
    fetch_or_create(letter_name, alteration)
  end

  def self.fetch_or_create(letter_name, alteration)
    @spellings ||= {}
    hash_key = [letter_name, alteration].join
    @spellings[hash_key] ||= new(letter_name, alteration)
  end

  def initialize(letter_name, alteration = nil)
    @letter_name = HeadMusic::Rudiment::LetterName.get(letter_name.to_s)
    @alteration = HeadMusic::Rudiment::Alteration.get(alteration)
    alteration_semitones = @alteration ? @alteration.semitones : 0
    @pitch_class = HeadMusic::Rudiment::PitchClass.get(letter_name.pitch_class + alteration_semitones)
  end

  def name
    [letter_name, alteration].join
  end

  def to_s
    name
  end

  def ==(other)
    other = HeadMusic::Rudiment::Spelling.get(other)
    to_s == other.to_s
  end

  def scale(scale_type_name = nil)
    HeadMusic::Rudiment::Scale.get(self, scale_type_name)
  end

  def natural?
    !alteration || alteration.natural?
  end

  private_class_method :new

  private

  def enharmonic_equivalence
    @enharmonic_equivalence ||= EnharmonicEquivalence.get(self)
  end

  # Enharmonic equivalence occurs when two spellings refer to the same pitch class, such as D# and Eb.
  class EnharmonicEquivalence
    def self.get(spelling)
      spelling = HeadMusic::Rudiment::Spelling.get(spelling)
      @enharmonic_equivalences ||= {}
      @enharmonic_equivalences[spelling.to_s] ||= new(spelling)
    end

    attr_reader :spelling

    def initialize(spelling)
      @spelling = HeadMusic::Rudiment::Spelling.get(spelling)
    end

    def enharmonic_equivalent?(other)
      other = HeadMusic::Rudiment::Spelling.get(other)
      spelling != other && spelling.pitch_class_number == other.pitch_class_number
    end

    alias_method :enharmonic?, :enharmonic_equivalent?
    alias_method :equivalent?, :enharmonic_equivalent?

    private_class_method :new
  end
end
