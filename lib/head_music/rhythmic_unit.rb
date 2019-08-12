# frozen_string_literal: true

# A rhythmic unit is a rudiment of duration consisting of doublings and divisions of a whole note.
class HeadMusic::RhythmicUnit
  include HeadMusic::NamedRudiment

  MULTIPLES = ['whole', 'double whole', 'longa', 'maxima'].freeze
  FRACTIONS = [
    'whole', 'half', 'quarter', 'eighth', 'sixteenth', 'thirty-second',
    'sixty-fourth', 'hundred twenty-eighth', 'two hundred fifty-sixth',
  ].freeze

  BRITISH_MULTIPLE_NAMES = %w[semibreve breve longa maxima].freeze
  BRITISH_DIVISION_NAMES = %w[
    semibreve minim crotchet quaver semiquaver demisemiquaver
    hemidemisemiquaver semihemidemisemiquaver demisemihemidemisemiquaver
  ].freeze

  def self.for_denominator_value(denominator)
    get(FRACTIONS[Math.log2(denominator).to_i])
  end

  attr_reader :numerator, :denominator

  def self.get(name)
    get_by_name(name)
  end

  def initialize(canonical_name)
    @name = canonical_name
    @numerator = 2**numerator_exponent
    @denominator = 2**denominator_exponent
  end

  def relative_value
    @numerator.to_f / @denominator
  end

  def ticks
    HeadMusic::Rhythm::PPQN * 4 * relative_value
  end

  def notehead
    return :maxima if relative_value == 8
    return :longa if relative_value == 4
    return :breve if relative_value == 2
    return :open if [0.5, 1].include? relative_value

    :closed
  end

  def flags
    FRACTIONS.include?(name) ? [FRACTIONS.index(name) - 2, 0].max : 0
  end

  def stemmed?
    relative_value < 1
  end

  def british_name
    if multiple?
      BRITISH_MULTIPLE_NAMES[MULTIPLES.index(name)]
    elsif fraction?
      BRITISH_DIVISION_NAMES[FRACTIONS.index(name)]
    elsif BRITISH_MULTIPLE_NAMES.include?(name) || BRITISH_DIVISION_NAMES.include?(name)
      name
    end
  end

  private_class_method :new

  private

  def multiple?
    MULTIPLES.include?(name)
  end

  def fraction?
    FRACTIONS.include?(name)
  end

  def numerator_exponent
    multiples_keys.index(name.gsub(/\W+/, '_')) || british_multiples_keys.index(name.gsub(/\W+/, '_')) || 0
  end

  def multiples_keys
    MULTIPLES.map { |multiple| multiple.gsub(/\W+/, '_') }
  end

  def british_multiples_keys
    BRITISH_MULTIPLE_NAMES.map { |multiple| multiple.gsub(/\W+/, '_') }
  end

  def denominator_exponent
    fractions_keys.index(name.gsub(/\W+/, '_')) || british_fractions_keys.index(name.gsub(/\W+/, '_')) || 0
  end

  def fractions_keys
    FRACTIONS.map { |fraction| fraction.gsub(/\W+/, '_') }
  end

  def british_fractions_keys
    BRITISH_DIVISION_NAMES.map { |fraction| fraction.gsub(/\W+/, '_') }
  end
end
