# A module for musical analysis
module HeadMusic::Analysis; end

# A diatonic interval is the distance between two spelled pitches.
class HeadMusic::Analysis::DiatonicInterval
  include Comparable
  include HeadMusic::Named

  NUMBER_NAMES = %w[
    unison second third fourth fifth sixth seventh octave
    ninth tenth eleventh twelfth thirteenth fourteenth fifteenth
    sixteenth seventeenth
  ].freeze
  NAME_SUFFIXES = Hash.new("th").merge(1 => "st", 2 => "nd", 3 => "rd").freeze

  QUALITY_SEMITONES = {
    unison: {perfect: 0},
    second: {major: 2},
    third: {major: 4},
    fourth: {perfect: 5},
    fifth: {perfect: 7},
    sixth: {major: 9},
    seventh: {major: 11},
    octave: {perfect: 12},
    ninth: {major: 14},
    tenth: {major: 16},
    eleventh: {perfect: 17},
    twelfth: {perfect: 19},
    thirteenth: {major: 21},
    fourteenth: {major: 23},
    fifteenth: {perfect: 24},
    sixteenth: {major: 26},
    seventeenth: {major: 28}
  }.freeze

  QUALITY_ABBREVIATIONS = {
    P: "perfect",
    M: "major",
    m: "minor",
    d: "diminished",
    A: "augmented"
  }.freeze

  attr_reader :lower_pitch, :higher_pitch

  delegate :perfect?, :major?, :minor?, :diminished?, :augmented?, :doubly_diminished?, :doubly_augmented?, to: :quality

  delegate :step?, :skip?, :leap?, :large_leap?, to: :category
  delegate(
    :simple_number, :octaves, :number, :simple?, :compound?, :semitones, :simple_semitones, :steps, :simple_steps,
    to: :size
  )
  delegate(
    :simple_name, :quality_name, :simple_number_name, :number_name, :shorthand,
    to: :naming
  )

  alias_method :to_i, :semitones

  # Override Named module methods to use computed name from naming
  def name(locale_code: nil)
    if locale_code
      # Try to get translation from locale files
      name_key = naming.name.downcase.gsub(' ', '_').to_sym
      translation = I18n.translate(name_key, scope: "head_music.diatonic_intervals", locale: locale_code, default: nil)
      translation || naming.name
    else
      naming.name
    end
  end

  def to_s
    name
  end

  # Accepts a name and returns the interval with middle c on the bottom
  def self.get(identifier)
    if identifier.is_a?(String) || identifier.is_a?(Symbol)
      name = Parser.new(identifier)
      semitones = Semitones.new(name.degree_name.to_sym, name.quality_name).count
      higher_pitch = HeadMusic::Rudiment::Pitch.from_number_and_letter(HeadMusic::Rudiment::Pitch.middle_c + semitones, name.higher_letter)
      interval = new(HeadMusic::Rudiment::Pitch.middle_c, higher_pitch)
      interval.ensure_localized_name(name: identifier.to_s)
      interval
    else
      identifier
    end
  end

  def initialize(first_pitch, second_pitch)
    first_pitch = HeadMusic::Rudiment::Pitch.get(first_pitch)
    second_pitch = HeadMusic::Rudiment::Pitch.get(second_pitch)
    @lower_pitch, @higher_pitch = [first_pitch, second_pitch].sort
  end

  def spans?(pitch)
    pitch.between?(lower_pitch, higher_pitch)
  end

  def quality
    HeadMusic::Rudiment::Quality.get(quality_name)
  end

  def inversion
    inverted_low_pitch = lower_pitch
    while inverted_low_pitch < higher_pitch
      inverted_low_pitch = HeadMusic::Rudiment::Pitch.fetch_or_create(lower_pitch.spelling, inverted_low_pitch.register + 1)
    end
    HeadMusic::Analysis::DiatonicInterval.new(higher_pitch, inverted_low_pitch)
  end
  alias_method :invert, :inversion

  def consonance(style = :standard_practice)
    consonance_for_perfect(style) ||
      consonance_for_major_and_minor ||
      HeadMusic::Rudiment::Consonance.get(:dissonant)
  end

  def consonance?(style = :standard_practice)
    consonance(style).perfect? || consonance(style).imperfect?
  end
  alias_method :consonant?, :consonance?

  def perfect_consonance?(style = :standard_practice)
    consonance(style).perfect?
  end

  def imperfect_consonance?(style = :standard_practice)
    consonance(style).imperfect?
  end

  def dissonance?(style = :standard_practice)
    consonance(style).dissonant?
  end

  def above(pitch)
    pitch = HeadMusic::Rudiment::Pitch.get(pitch)
    HeadMusic::Rudiment::Pitch.from_number_and_letter(pitch + semitones, pitch.letter_name.steps_up(number - 1))
  end

  def below(pitch)
    pitch = HeadMusic::Rudiment::Pitch.get(pitch)
    HeadMusic::Rudiment::Pitch.from_number_and_letter(pitch - semitones, pitch.letter_name.steps_down(number - 1))
  end

  def interval_class
    [simple_semitones, 12 - simple_semitones].min
  end

  def interval_class_name
    "ic #{interval_class}"
  end

  # diatonic set theory
  alias_method :specific_interval, :simple_semitones
  alias_method :diatonic_generic_interval, :simple_steps

  def <=>(other)
    other = self.class.get(other) unless other.is_a?(HeadMusic::Analysis::DiatonicInterval)
    semitones <=> other.semitones
  end

  NUMBER_NAMES.each do |interval_name|
    define_method(:"#{interval_name}?") { number_name == interval_name }
  end

  NUMBER_NAMES.first(8).each do |method_name|
    define_method(:"#{method_name}_or_compound?") { simple_number_name == method_name }
  end

  private

  def size
    @size ||= Size.new(@lower_pitch, @higher_pitch)
  end

  def category
    @category ||= Category.new(number)
  end

  def naming
    @naming ||= Naming.new(number: number, semitones: semitones)
  end

  def consonance_for_perfect(style = :standard_practice)
    HeadMusic::Rudiment::Consonance.get(dissonant_fourth?(style) ? :dissonant : :perfect) if perfect?
  end

  def consonance_for_major_and_minor
    HeadMusic::Rudiment::Consonance.get((third_or_compound? || sixth_or_compound?) ? :imperfect : :dissonant) if major? || minor?
  end

  def dissonant_fourth?(style = :standard_practice)
    fourth_or_compound? && style == :two_part_harmony
  end
end
