# frozen_string_literal: true

# A diatonic interval is the distance between two spelled pitches.
class HeadMusic::DiatonicInterval
  include Comparable

  NUMBER_NAMES = %w[
    unison second third fourth fifth sixth seventh octave
    ninth tenth eleventh twelfth thirteenth fourteenth fifteenth
    sixteenth seventeenth
  ].freeze
  NAME_SUFFIXES = Hash.new('th').merge(1 => 'st', 2 => 'nd', 3 => 'rd').freeze

  QUALITY_SEMITONES = {
    unison: { perfect: 0 },
    second: { major: 2 },
    third: { major: 4 },
    fourth: { perfect: 5 },
    fifth: { perfect: 7 },
    sixth: { major: 9 },
    seventh: { major: 11 },
    octave: { perfect: 12 },
    ninth: { major: 14 },
    tenth: { major: 16 },
    eleventh: { perfect: 17 },
    twelfth: { perfect: 19 },
    thirteenth: { major: 21 },
    fourteenth: { major: 23 },
    fifteenth: { perfect: 24 },
    sixteenth: { major: 26 },
    seventeenth: { major: 28 },
  }.freeze

  QUALITY_ABBREVIATIONS = {
    P: 'perfect',
    M: 'major',
    m: 'minor',
    d: 'diminished',
    A: 'augmented',
  }.freeze

  attr_reader :lower_pitch, :higher_pitch

  delegate :to_s, to: :name
  delegate :perfect?, :major?, :minor?, :diminished?, :augmented?, :doubly_diminished?, :doubly_augmented?, to: :quality

  # Interprets a string or symbol
  class Parser
    attr_reader :identifier

    def initialize(identifier)
      @identifier = expand(identifier)
    end

    def words
      identifier.to_s.split(/[_ ]+/)
    end

    def quality_name
      words[0..-2].join(' ').to_sym
    end

    def degree_name
      words.last
    end

    def steps
      NUMBER_NAMES.index(degree_name)
    end

    def higher_letter
      HeadMusic::Pitch.middle_c.letter_name.steps_up(steps)
    end

    def expand(identifier)
      if /[A-Z]\d{1,2}/i.match?(identifier)
        number = NUMBER_NAMES[identifier.gsub(/[A-Z]/i, '').to_i - 1]
        return [quality_for(identifier[0]), number].join('_').to_sym
      end
      identifier
    end

    def quality_for(abbreviation)
      QUALITY_ABBREVIATIONS[abbreviation.to_sym] ||
        QUALITY_ABBREVIATIONS[abbreviation.upcase.to_sym] ||
        QUALITY_ABBREVIATIONS[abbreviation.downcase.to_sym]
    end
  end

  # Accepts a name and a quality and returns the number of semitones
  class Semitones
    attr_reader :count

    def initialize(name, quality_name)
      @count ||= Semitones.degree_quality_semitones.dig(name, quality_name)
    end

    def self.degree_quality_semitones
      @degree_quality_semitones ||= begin
        {}.tap do |degree_quality_semitones|
          QUALITY_SEMITONES.each do |degree_name, qualities|
            default_quality = qualities.keys.first
            default_semitones = qualities[default_quality]
            degree_quality_semitones[degree_name] = _semitones_for_degree(default_quality, default_semitones)
          end
        end
      end
    end

    def self._semitones_for_degree(quality, default_semitones)
      {}.tap do |semitones|
        _degree_quality_modifications(quality).each do |current_quality, delta|
          semitones[current_quality] = default_semitones + delta
        end
      end
    end

    def self._degree_quality_modifications(quality)
      if quality == :perfect
        HeadMusic::Quality::PERFECT_INTERVAL_MODIFICATION.invert
      else
        HeadMusic::Quality::MAJOR_INTERVAL_MODIFICATION.invert
      end
    end
  end

  # Accepts the letter name count between two notes and categorizes the interval
  class Category
    attr_reader :number

    def initialize(number)
      @number = number
    end

    def step?
      number == 2
    end

    def skip?
      number == 3
    end

    def leap?
      number >= 3
    end

    def large_leap?
      number > 3
    end
  end

  # Encapsulate the distance methods of the interval
  class Size
    attr_reader :low_pitch, :high_pitch

    def initialize(pitch1, pitch2)
      @low_pitch, @high_pitch = *[pitch1, pitch2].sort
    end

    def number
      @number ||= @low_pitch.steps_to(@high_pitch) + 1
    end

    def simple_number
      @simple_number ||= octave_equivalent? ? 8 : (number - 1) % 7 + 1
    end

    def octaves
      @octaves ||= number / 8
    end

    def simple?
      number <= 8
    end

    def compound?
      !simple?
    end

    def simple_semitones
      @simple_semitones ||= semitones % 12
    end

    def semitones
      (high_pitch - low_pitch).to_i
    end

    def steps
      number - 1
    end

    def simple_steps
      steps % 7
    end

    private

    def octave_equivalent?
      number > 1 && ((number - 1) % 7).zero?
    end
  end

  # Accepts a number and number of semitones and privides the naming methods.
  class Naming
    attr_reader :number, :semitones

    def initialize(number:, semitones:)
      @number = number
      @semitones = semitones
    end

    def simple_semitones
      @simple_semitones ||= semitones % 12
    end

    def simple_number
      @simple_number ||= octave_equivalent? ? 8 : (number - 1) % 7 + 1
    end

    def simple_name
      [quality_name, simple_number_name].join(' ')
    end

    def quality_name
      starting_quality = QUALITY_SEMITONES[simple_number_name.to_sym].keys.first
      delta = simple_semitones - (QUALITY_SEMITONES[simple_number_name.to_sym][starting_quality] % 12)
      delta -= 12 while delta >= 6
      HeadMusic::Quality.from(starting_quality, delta)
    end

    def simple_number_name
      NUMBER_NAMES[simple_number - 1]
    end

    def number_name
      NUMBER_NAMES[number - 1] || (number.to_s + NAME_SUFFIXES[number % 10])
    end

    def name
      if named_number?
        [quality_name, number_name].join(' ')
      elsif simple_name == 'perfect octave'
        "#{octaves.humanize} octaves"
      else
        "#{octaves.humanize} octaves and #{quality.article} #{simple_name}"
      end
    end

    def shorthand
      step_shorthand = number == 1 ? 'U' : number
      [quality.shorthand, step_shorthand].join
    end

    private

    def named_number?
      number < NUMBER_NAMES.length
    end

    def quality
      @quality ||= HeadMusic::Quality.get(quality_name)
    end

    def octaves
      @octaves ||= semitones / 12
    end

    def octave_equivalent?
      number > 1 && ((number - 1) % 7).zero?
    end
  end

  delegate :step?, :skip?, :leap?, :large_leap?, to: :category
  delegate(
    :simple_number, :octaves, :number, :simple?, :compound?, :semitones, :simple_semitones, :steps, :simple_steps,
    to: :size
  )
  delegate(
    :simple_semitones, :simple_name, :quality_name, :simple_number_name, :number_name, :name, :shorthand,
    to: :naming
  )

  # Accepts a name and returns the interval with middle c on the bottom
  def self.get(identifier)
    name = Parser.new(identifier)
    semitones = Semitones.new(name.degree_name.to_sym, name.quality_name).count
    higher_pitch = HeadMusic::Pitch.from_number_and_letter(HeadMusic::Pitch.middle_c + semitones, name.higher_letter)
    new(HeadMusic::Pitch.middle_c, higher_pitch)
  end

  def initialize(pitch1, pitch2)
    pitch1 = HeadMusic::Pitch.get(pitch1)
    pitch2 = HeadMusic::Pitch.get(pitch2)
    @lower_pitch, @higher_pitch = [pitch1, pitch2].sort
  end

  def quality
    HeadMusic::Quality.get(quality_name)
  end

  def inversion
    inverted_low_pitch = lower_pitch
    while inverted_low_pitch < higher_pitch
      inverted_low_pitch = HeadMusic::Pitch.fetch_or_create(lower_pitch.spelling, inverted_low_pitch.octave + 1)
    end
    HeadMusic::DiatonicInterval.new(higher_pitch, inverted_low_pitch)
  end
  alias invert inversion

  def consonance(style = :standard_practice)
    consonance_for_perfect(style) ||
      consonance_for_major_and_minor ||
      HeadMusic::Consonance.get(:dissonant)
  end

  def consonance?(style = :standard_practice)
    consonance(style).perfect? || consonance(style).imperfect?
  end
  alias consonant? consonance?

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
    pitch = HeadMusic::Pitch.get(pitch)
    HeadMusic::Pitch.from_number_and_letter(pitch + semitones, pitch.letter_name.steps_up(number - 1))
  end

  def below(pitch)
    pitch = HeadMusic::Pitch.get(pitch)
    HeadMusic::Pitch.from_number_and_letter(pitch - semitones, pitch.letter_name.steps_down(number - 1))
  end

  # diatonic set theory
  alias specific_interval simple_semitones
  alias diatonic_generic_interval simple_steps

  def <=>(other)
    other = self.class.get(other) unless other.is_a?(HeadMusic::DiatonicInterval)
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

  def named_number?
    number < NUMBER_NAMES.length
  end

  def consonance_for_perfect(style = :standard_practice)
    HeadMusic::Consonance.get(dissonant_fourth?(style) ? :dissonant : :perfect) if perfect?
  end

  def consonance_for_major_and_minor
    HeadMusic::Consonance.get(third_or_compound? || sixth_or_compound? ? :imperfect : :dissonant) if major? || minor?
  end

  def dissonant_fourth?(style = :standard_practice)
    fourth_or_compound? && style == :two_part_harmony
  end
end
