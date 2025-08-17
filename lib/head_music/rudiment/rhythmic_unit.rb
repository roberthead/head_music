# A module for music rudiments
module HeadMusic::Rudiment; end

# A rhythmic unit is a rudiment of duration consisting of doublings and divisions of a whole note.
class HeadMusic::Rudiment::RhythmicUnit < HeadMusic::Rudiment::Base
  include HeadMusic::Named
  include Comparable

  AMERICAN_MULTIPLES_NAMES = [
    "whole", "double whole", "longa", "maxima"
  ].freeze

  AMERICAN_DIVISIONS_NAMES = [
    "whole", "half", "quarter", "eighth", "sixteenth", "thirty-second",
    "sixty-fourth", "hundred twenty-eighth", "two hundred fifty-sixth"
  ].freeze

  AMERICAN_DURATIONS = (AMERICAN_MULTIPLES_NAMES + AMERICAN_DIVISIONS_NAMES).freeze

  PATTERN = /#{Regexp.union(AMERICAN_DURATIONS)}/

  # British terminology for note values longer than a whole note
  BRITISH_MULTIPLES_NAMES = %w[semibreve breve longa maxima].freeze

  # British terminology for standard note divisions
  BRITISH_DIVISIONS_NAMES = %w[
    semibreve minim crotchet quaver semiquaver demisemiquaver
    hemidemisemiquaver semihemidemisemiquaver demisemihemidemisemiquaver
  ].freeze

  # Notehead symbols used for different note values
  NOTEHEADS = {
    maxima: 8.0,
    longa: 4.0,
    breve: 2.0,
    open: [0.5, 1.0],
    closed: :default
  }.freeze

  def self.for_denominator_value(denominator)
    return nil unless denominator.is_a?(Numeric) && denominator > 0
    return nil unless (denominator & (denominator - 1)) == 0  # Check if power of 2

    index = Math.log2(denominator).to_i
    return nil if index >= AMERICAN_DIVISIONS_NAMES.length

    get(AMERICAN_DIVISIONS_NAMES[index])
  end

  attr_reader :numerator, :denominator

  def self.get(name)
    get_by_name(name)
  end

  def self.all
    @all ||= (AMERICAN_MULTIPLES_NAMES.reverse + AMERICAN_DIVISIONS_NAMES).uniq.map { |name| get(name) }.compact
  end

  # Check if a name represents a valid rhythmic unit
  def self.valid_name?(name)
    normalized = normalize_name(name)
    all_normalized_names.include?(normalized)
  end

  def self.all_normalized_names
    @all_normalized_names ||= (
      AMERICAN_MULTIPLES_NAMES.map { |n| normalize_name(n) } +
      AMERICAN_DIVISIONS_NAMES.map { |n| normalize_name(n) } +
      BRITISH_MULTIPLES_NAMES.map { |n| normalize_name(n) } +
      BRITISH_DIVISIONS_NAMES.map { |n| normalize_name(n) }
    ).uniq
  end

  def initialize(canonical_name)
    raise ArgumentError, "Name cannot be nil or empty" if canonical_name.to_s.strip.empty?

    self.name = canonical_name
    @numerator = 2**numerator_exponent
    @denominator = 2**denominator_exponent
  end

  def relative_value
    @numerator.to_f / @denominator
  end

  def ticks
    HeadMusic::Rudiment::Rhythm::PPQN * 4 * relative_value
  end

  def notehead
    value = relative_value
    return :maxima if value == NOTEHEADS[:maxima]
    return :longa if value == NOTEHEADS[:longa]
    return :breve if value == NOTEHEADS[:breve]
    return :open if NOTEHEADS[:open].include?(value)

    :closed
  end

  def flags
    AMERICAN_DIVISIONS_NAMES.include?(name) ? [AMERICAN_DIVISIONS_NAMES.index(name) - 2, 0].max : 0
  end

  def stemmed?
    relative_value < 1
  end

  # Returns true if this note value is commonly used in modern notation
  def common?
    AMERICAN_DIVISIONS_NAMES[0..6].include?(name) || BRITISH_DIVISIONS_NAMES[0..6].include?(name)
  end

  def <=>(other)
    return nil unless other.is_a?(self.class)

    relative_value <=> other.relative_value
  end

  def british_name
    if has_american_multiple_name?
      index = AMERICAN_MULTIPLES_NAMES.index(name)
      return BRITISH_MULTIPLES_NAMES[index] unless index.nil?
    elsif has_american_division_name?
      index = AMERICAN_DIVISIONS_NAMES.index(name)
      return BRITISH_DIVISIONS_NAMES[index] unless index.nil?
    elsif BRITISH_MULTIPLES_NAMES.include?(name) || BRITISH_DIVISIONS_NAMES.include?(name)
      return name
    end

    nil # Return nil if no British equivalent found
  end

  private_class_method :new

  def self.normalize_name(name)
    name.to_s.gsub(/\W+/, "_")
  end

  private

  def has_american_multiple_name?
    AMERICAN_MULTIPLES_NAMES.include?(name)
  end

  def has_american_division_name?
    AMERICAN_DIVISIONS_NAMES.include?(name)
  end

  def numerator_exponent
    normalized_name = self.class.normalize_name(name)
    multiples_keys.index(normalized_name) || british_multiples_keys.index(normalized_name) || 0
  end

  def multiples_keys
    AMERICAN_MULTIPLES_NAMES.map { |multiple| self.class.normalize_name(multiple) }
  end

  def british_multiples_keys
    BRITISH_MULTIPLES_NAMES.map { |multiple| self.class.normalize_name(multiple) }
  end

  def denominator_exponent
    normalized_name = self.class.normalize_name(name)
    fractions_keys.index(normalized_name) || british_fractions_keys.index(normalized_name) || 0
  end

  def fractions_keys
    AMERICAN_DIVISIONS_NAMES.map { |fraction| self.class.normalize_name(fraction) }
  end

  def british_fractions_keys
    BRITISH_DIVISIONS_NAMES.map { |fraction| self.class.normalize_name(fraction) }
  end
end
