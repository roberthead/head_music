# frozen_string_literal: true

# A pitch is a named frequency represented by a spelling and an octive.
class HeadMusic::Pitch
  include Comparable

  attr_reader :spelling, :register

  delegate :letter_name, to: :spelling
  delegate :series_ascending, :series_descending, to: :letter_name, prefix: true
  delegate :sign, :sharp?, :flat?, to: :spelling
  delegate :pitch_class, to: :spelling
  delegate :number, to: :pitch_class, prefix: true
  delegate :pitch_class_number, to: :natural, prefix: true
  delegate :semitones, to: :sign, prefix: true, allow_nil: true
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
    from_pitch_class(value) ||
      from_name(value) ||
      from_number(value)
  end

  def self.middle_c
    get('C4')
  end

  def self.concert_a
    get('A4')
  end

  def self.from_pitch_class(pitch_class)
    return nil unless pitch_class.is_a?(HeadMusic::PitchClass)

    fetch_or_create(pitch_class.sharp_spelling)
  end

  def self.from_name(name)
    return nil unless name == name.to_s

    fetch_or_create(HeadMusic::Spelling.get(name), HeadMusic::Register.get(name).to_i)
  end

  def self.from_number(number)
    return nil unless number == number.to_i

    fetch_or_create(HeadMusic::Spelling.from_number(number), (number.to_i / 12) - 1)
  end

  def self.from_number_and_letter(number, letter_name)
    letter_name = HeadMusic::LetterName.get(letter_name)
    natural_letter_pitch = natural_letter_pitch(number, letter_name)
    sign_interval = natural_letter_pitch.smallest_interval_to(HeadMusic::PitchClass.get(number))
    sign = HeadMusic::Sign.by(:semitones, sign_interval) if sign_interval != 0
    spelling = HeadMusic::Spelling.fetch_or_create(letter_name, sign)
    fetch_or_create(spelling, natural_letter_pitch.register)
  end

  def self.natural_letter_pitch(number, letter_name)
    natural_letter_pitch = get(HeadMusic::LetterName.get(letter_name).pitch_class)
    natural_letter_pitch += 12 while (number.to_i - natural_letter_pitch.to_i) >= 6
    natural_letter_pitch -= 12 while (number.to_i - natural_letter_pitch.to_i) <= -6
    get(natural_letter_pitch)
  end

  def self.fetch_or_create(spelling, register = nil)
    register ||= HeadMusic::Register::DEFAULT
    return unless spelling && (-1..9).cover?(register)

    @pitches ||= {}
    hash_key = [spelling, register].join
    @pitches[hash_key] ||= new(spelling, register)
  end

  def initialize(spelling, register)
    @spelling = HeadMusic::Spelling.get(spelling.to_s)
    @register = register.to_i
  end

  def name
    [spelling, register].join
  end

  def midi_note_number
    (register + 1) * 12 + letter_name.pitch_class.to_i + sign_semitones.to_i
  end

  alias midi midi_note_number
  alias number midi_note_number

  def to_s
    name
  end

  def to_i
    midi_note_number
  end

  def natural
    HeadMusic::Pitch.get(to_s.gsub(HeadMusic::Sign.matcher, ''))
  end

  def +(other)
    if other.is_a?(HeadMusic::DiatonicInterval)
      # return a pitch
      other.above(self)
    else
      # assume value represents an interval in semitones and return another pitch
      HeadMusic::Pitch.get(to_i + other.to_i)
    end
  end

  def -(other)
    if other.is_a?(HeadMusic::DiatonicInterval)
      # return a pitch
      other.below(self)
    elsif other.is_a?(HeadMusic::Pitch)
      # return an interval
      HeadMusic::ChromaticInterval.get(to_i - other.to_i)
    else
      # assume value represents an interval in semitones and return another pitch
      HeadMusic::Pitch.get(to_i - other.to_i)
    end
  end

  def ==(other)
    other = HeadMusic::Pitch.get(other)
    to_s == other.to_s
  end

  def <=>(other)
    midi_note_number <=> other.midi_note_number
  end

  def scale(scale_type_name = nil)
    HeadMusic::Scale.get(self, scale_type_name)
  end

  def natural_steps(num_steps)
    HeadMusic::Pitch.get([target_letter_name(num_steps), register + octaves_delta(num_steps)].join)
  end

  def frequency
    tuning.frequency_for(self)
  end

  def steps_to(other)
    other = HeadMusic::Pitch.get(other)
    letter_name_steps_to(other) + 7 * octave_changes_to(other)
  end

  private_class_method :new

  private

  def octave_changes_to(other)
    other.register - register - octave_adjustment_to(other)
  end

  def octave_adjustment_to(other)
    (pitch_class_above?(other) ? 1 : 0)
  end

  def pitch_class_above?(other)
    natural_pitch_class_number > other.natural_pitch_class_number
  end

  def enharmonic_equivalence
    @enharmonic_equivalence ||= HeadMusic::Pitch::EnharmonicEquivalence.get(self)
  end

  def octave_equivalence
    @octave_equivalence ||= HeadMusic::Pitch::OctaveEquivalence.get(self)
  end

  def tuning
    @tuning ||= HeadMusic::Tuning.new
  end

  def octaves_delta(num_steps)
    octaves_delta = (num_steps.abs / 7) * (num_steps >= 0 ? 1 : -1)
    if wrapped_down?(num_steps)
      octaves_delta -= 1
    elsif wrapped_up?(num_steps)
      octaves_delta += 1
    end
    octaves_delta
  end

  def wrapped_down?(num_steps)
    num_steps.negative? && target_letter_name(num_steps).position > letter_name.position
  end

  def wrapped_up?(num_steps)
    num_steps.positive? && target_letter_name(num_steps).position < letter_name.position
  end

  def target_letter_name(num_steps)
    @target_letter_name ||= {}
    @target_letter_name[num_steps] ||= letter_name.steps_up(num_steps)
  end
end
