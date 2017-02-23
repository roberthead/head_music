class HeadMusic::RhythmicUnit
  MULTIPLES = ['whole', 'double whole', 'longa', 'maxima']
  DIVISIONS = ['whole', 'half', 'quarter', 'eighth', 'sixteenth', 'thirty-second', 'sixty-fourth', 'hundred twenty-eighth note', 'two hundred fifty-sixth note']

  BRITISH_MULTIPLE_NAMES = %w[semibreve breve longa maxima]
  BRITISH_DIVISION_NAMES = %w[semibreve minim crotchet quaver semiquaver demisemiquaver hemidemisemiquaver semihemidemisemiquaver demisemihemidemisemiquaver]

  def self.get(name)
    @rhythmic_values ||= {}
    @rhythmic_values[name.to_s] ||= new(name.to_s)
  end
  singleton_class.send(:alias_method, :[], :get)

  attr_reader :name
  delegate :to_s, to: :name
  delegate :to_i, to: :relative_value

  def initialize(canonical_name)
    @name ||= canonical_name
  end

  def relative_value
    @relative_value ||=
      if MULTIPLES.include?(name)
        1.0 * 2**MULTIPLES.index(name)
      elsif DIVISIONS.include?(name)
        1.0 / 2**DIVISIONS.index(name)
      end
  end

  def per_whole
    @per_whole ||=
      if MULTIPLES.include?(name)
        1.0 / 2**MULTIPLES.index(name)
      elsif DIVISIONS.include?(name)
        1.0 * 2**DIVISIONS.index(name)
      end
  end

  def note_head
    return :breve if relative_value == 2
    return :open if relative_value >= 0.5
    :closed
  end

  def flags
    DIVISIONS.include?(name) ? [DIVISIONS.index(name) - 2, 0].max : 0
  end

  def has_stem?
    relative_value < 1
  end

  def british_name
    if MULTIPLES.include?(name)
      BRITISH_MULTIPLE_NAMES[MULTIPLES.index(name)]
    elsif DIVISIONS.include?(name)
      BRITISH_DIVISION_NAMES[DIVISIONS.index(name)]
    end
  end

  private_class_method :new
end
