class HeadMusic::RhythmicUnit
  MULTIPLES = ['whole', 'double whole', 'longa', 'maxima']
  FRACTIONS = ['whole', 'half', 'quarter', 'eighth', 'sixteenth', 'thirty-second', 'sixty-fourth', 'hundred twenty-eighth', 'two hundred fifty-sixth']

  BRITISH_MULTIPLE_NAMES = %w[semibreve breve longa maxima]
  BRITISH_DIVISION_NAMES = %w[semibreve minim crotchet quaver semiquaver demisemiquaver hemidemisemiquaver semihemidemisemiquaver demisemihemidemisemiquaver]

  def self.get(name)
    @rhythmic_units ||= {}
    hash_key = HeadMusic::Utilities::HashKey.for(name)
    @rhythmic_units[hash_key] ||= new(name.to_s)
  end
  singleton_class.send(:alias_method, :[], :get)

  def self.for_denominator_value(denominator)
    get(FRACTIONS[Math.log2(denominator).to_i])
  end

  attr_reader :name, :numerator, :denominator
  delegate :to_s, to: :name

  def initialize(canonical_name)
    @name ||= canonical_name
    @numerator ||= MULTIPLES.include?(name) ? 2**MULTIPLES.index(name) : 1
    @denominator ||= FRACTIONS.include?(name) ? 2**FRACTIONS.index(name) : 1
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
    end
  end

  private_class_method :new
end
