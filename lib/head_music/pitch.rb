# frozen_string_literal: true

# A pitch is a named frequency represented by a spelling and an octive.
class HeadMusic::Pitch
  include Comparable

  attr_reader :spelling
  attr_reader :octave

  delegate :letter_name, :letter_name_cycle, to: :spelling
  delegate :sign, :sharp?, :flat?, to: :spelling
  delegate :pitch_class, to: :spelling
  delegate :semitones, to: :sign, prefix: true, allow_nil: true

  delegate :smallest_interval_to, to: :pitch_class

  def self.definition
    'A pitch is a named frequency represented by a spelling and an octave, such as B♭3.'
  end

  def self.get(value)
    from_name(value) || from_number(value)
  end

  def self.middle_c
    get('C4')
  end

  def self.from_name(name)
    return nil unless name == name.to_s
    fetch_or_create(HeadMusic::Spelling.get(name), HeadMusic::Octave.get(name).to_i)
  end

  def self.from_number(number)
    return nil unless number == number.to_i
    spelling = HeadMusic::Spelling.from_number(number)
    octave = (number.to_i / 12) - 1
    fetch_or_create(spelling, octave)
  end

  def self.from_number_and_letter(number, letter_name)
    letter_name = HeadMusic::LetterName.get(letter_name)
    natural_letter_pitch = natural_letter_pitch(number, letter_name)
    sign_interval = natural_letter_pitch.smallest_interval_to(HeadMusic::PitchClass.get(number))
    sign = HeadMusic::Sign.by(:semitones, sign_interval) if sign_interval != 0
    spelling = HeadMusic::Spelling.fetch_or_create(letter_name, sign)
    fetch_or_create(spelling, natural_letter_pitch.octave)
  end

  def self.natural_letter_pitch(number, letter_name)
    natural_letter_pitch = get(HeadMusic::LetterName.get(letter_name).pitch_class)
    natural_letter_pitch += 12 while (number - natural_letter_pitch.to_i).to_i >= 11
    get(natural_letter_pitch)
  end

  def self.fetch_or_create(spelling, octave)
    return unless spelling && (-1..9).cover?(octave)
    @pitches ||= {}
    hash_key = [spelling, octave].join
    @pitches[hash_key] ||= new(spelling, octave)
  end

  def initialize(spelling, octave)
    @spelling = HeadMusic::Spelling.get(spelling.to_s)
    @octave = octave.to_i
  end

  def name
    [spelling, octave].join
  end

  def midi_note_number
    (octave + 1) * 12 + letter_name.pitch_class.to_i + sign_semitones.to_i
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
    HeadMusic::Pitch.get(to_s.gsub(/[#b]/, ''))
  end

  def enharmonic?(other)
    midi_note_number == other.midi_note_number
  end

  alias enharmonic_equivalent? enharmonic?
  alias equivalent? enharmonic?

  def +(other)
    HeadMusic::Pitch.get(to_i + other.to_i)
  end

  def -(other)
    if other.is_a?(HeadMusic::Pitch)
      # return an interval
      HeadMusic::Interval.get(to_i - other.to_i)
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
    HeadMusic::Pitch.get([target_letter_name(num_steps), octave + octaves_delta(num_steps)].join)
  end

  def frequency
    tuning.frequency_for(self)
  end

  def octave_equivalent?(other)
    spelling == other.spelling && octave != other.octave
  end

  private_class_method :new

  private

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
    @target_letter_name[num_steps] ||= letter_name.steps(num_steps)
  end
end
