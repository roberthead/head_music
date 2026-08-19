module HeadMusic::Rudiment; end

# A pitch is a named frequency represented by a spelling and a register.
class HeadMusic::Rudiment::Pitch < HeadMusic::Rudiment::Base
  include Comparable

  SEMITONES_PER_OCTAVE = 12
  # MIDI note 0 is C-1, so the register numbering starts an octave below zero.
  LOWEST_MIDI_REGISTER = -1

  attr_reader :spelling, :register

  delegate :letter_name, :alteration, :pitch_class, :sharp?, :flat?, to: :spelling
  delegate :series_ascending, :series_descending, to: :letter_name, prefix: true
  delegate :number, to: :pitch_class, prefix: true
  delegate :pitch_class_number, to: :natural, prefix: true
  delegate :semitones, to: :alteration, prefix: true, allow_nil: true
  delegate :steps_to, to: :letter_name, prefix: true

  delegate :smallest_interval_to, to: :pitch_class

  delegate :enharmonic_equivalent?, :enharmonic?, to: :enharmonic_equivalence
  delegate :octave_equivalent?, to: :octave_equivalence

  # Fetches a pitch identified by the information passed in.
  #
  # Accepts:
  #   - a Pitch instance
  #   - a PitchClass instance
  #   - a name string, such as 'Ab4'
  #   - a number corresponding to the midi note number
  def self.get(value)
    return value if value.is_a?(HeadMusic::Rudiment::Pitch)

    from_pitch_class(value) ||
      from_name(value) ||
      from_number(value)
  end

  def self.middle_c
    get("C4")
  end

  def self.concert_a
    get("A4")
  end

  def self.from_pitch_class(pitch_class)
    return nil unless pitch_class.is_a?(HeadMusic::Rudiment::PitchClass)

    fetch_or_create(pitch_class.sharp_spelling)
  end

  def self.from_name(name)
    return nil unless name == name.to_s

    Parser.parse(name)
  end

  def self.from_number(number)
    return nil unless number.respond_to?(:to_i)

    number_int = number.to_i
    return nil unless number == number_int

    fetch_or_create(HeadMusic::Rudiment::Spelling.from_number(number), register_of(number_int))
  end

  # The register comes from the natural letter pitch and the alteration from the
  # spelling, which measures it from the same place.
  def self.from_number_and_letter(number, letter_name)
    spelling = HeadMusic::Rudiment::Spelling.from_number_and_letter(number, letter_name)
    fetch_or_create(spelling, natural_letter_pitch(number, letter_name).register)
  end

  def self.natural_letter_pitch(number, letter_name)
    NaturalLetterPitch.get(number, letter_name)
  end

  # The inverse of the register term in #midi_note_number.
  def self.register_of(midi_note_number)
    midi_note_number / SEMITONES_PER_OCTAVE + LOWEST_MIDI_REGISTER
  end

  def self.fetch_or_create(spelling, register = nil)
    register ||= HeadMusic::Rudiment::Register::DEFAULT
    return unless spelling && (-1..9).cover?(register)

    fetch_or_register([spelling, register].join, spelling, register)
  end

  def initialize(spelling, register)
    @spelling = HeadMusic::Rudiment::Spelling.get(spelling.to_s)
    @register = register.to_i
  end

  def name
    [spelling, register].join
  end

  def midi_note_number
    (register - LOWEST_MIDI_REGISTER) * SEMITONES_PER_OCTAVE + spelling.semitones_above_c
  end

  alias_method :midi, :midi_note_number
  alias_method :number, :midi_note_number

  def to_s
    name
  end

  def pitched?
    true
  end

  def to_i
    midi_note_number
  end

  def helmholtz_notation
    HelmholtzNotation.new(spelling, register).to_s
  end

  def natural
    HeadMusic::Rudiment::Pitch.get([letter_name, register].join)
  end

  def +(other)
    Arithmetic.new(self, other).sum
  end

  def -(other)
    Arithmetic.new(self, other).difference
  end

  def ==(other)
    other = HeadMusic::Rudiment::Pitch.get(other)
    to_s == other.to_s
  end

  def <=>(other)
    midi_note_number <=> other.midi_note_number
  end

  def scale(scale_type_name = nil)
    HeadMusic::Rudiment::Scale.get(self, scale_type_name)
  end

  def natural_steps(num_steps)
    NaturalStep.new(letter_name, num_steps).applied_to(self)
  end

  def frequency
    tuning.frequency_for(self)
  end

  def steps_to(other)
    StepDistance.new(self, other).steps
  end

  private

  def enharmonic_equivalence
    @enharmonic_equivalence ||= HeadMusic::Rudiment::Pitch::EnharmonicEquivalence.get(self)
  end

  def octave_equivalence
    @octave_equivalence ||= HeadMusic::Rudiment::Pitch::OctaveEquivalence.get(self)
  end

  def tuning
    @tuning ||= HeadMusic::Rudiment::Tuning.new
  end
end
