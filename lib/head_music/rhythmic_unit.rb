class HeadMusic::RhythmicUnit
  include HeadMusic::NamedRudiment

  MULTIPLES = ['whole', 'double whole', 'longa', 'maxima']
  FRACTIONS = ['whole', 'half', 'quarter', 'eighth', 'sixteenth', 'thirty-second', 'sixty-fourth', 'hundred twenty-eighth', 'two hundred fifty-sixth']

  BRITISH_MULTIPLE_NAMES = %w[semibreve breve longa maxima]
  BRITISH_DIVISION_NAMES = %w[semibreve minim crotchet quaver semiquaver demisemiquaver hemidemisemiquaver semihemidemisemiquaver demisemihemidemisemiquaver]

  def self.for_denominator_value(denominator)
    get(FRACTIONS[Math.log2(denominator).to_i])
  end

  attr_reader :numerator, :denominator

  def self.get(name)
    get_by_name(name)
  end

  def initialize(canonical_name)
    @name ||= canonical_name
    ensure_numerator
    ensure_denominator
  end

  def relative_value
    @numerator.to_f / @denominator
  end

  def ticks
    HeadMusic::Rhythm::PPQN * 4 * relative_value
  end

  def notehead
    case relative_value
    when 8
      :maxima
    when 4
      :longa
    when 2
      :breve
    when 0.5, 1
      :open
    else
      :closed
    end
  end

  def flags
    FRACTIONS.include?(name) ? [FRACTIONS.index(name) - 2, 0].max : 0
  end

  def has_stem?
    relative_value < 1
  end

  def british_name
    if MULTIPLES.include?(name)
      BRITISH_MULTIPLE_NAMES[MULTIPLES.index(name)]
    elsif FRACTIONS.include?(name)
      BRITISH_DIVISION_NAMES[FRACTIONS.index(name)]
    elsif BRITISH_MULTIPLE_NAMES.include?(name) || BRITISH_DIVISION_NAMES.include?(name)
      name
    end
  end

  private_class_method :new

  private

  def ensure_numerator
    @numerator ||= 2**MULTIPLES.index(name) if MULTIPLES.include?(name)
    @numerator ||= 2**BRITISH_MULTIPLE_NAMES.index(name) if BRITISH_MULTIPLE_NAMES.include?(name)
    @numerator ||= 1
  end

  def ensure_denominator
    @denominator ||= 2**FRACTIONS.index(name) if FRACTIONS.include?(name)
    @denominator ||= 2**BRITISH_DIVISION_NAMES.index(name) if BRITISH_DIVISION_NAMES.include?(name)
    @denominator ||= 1
  end
end
