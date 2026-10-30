# A module for musical content
module HeadMusic::Rudiment; end

# A rhythmic value is one written note value: a rhythmic unit, any number of
# dots, and an optional tuplet ratio. Values tied together make a
# RhythmicDuration.
class HeadMusic::Rudiment::RhythmicValue
  include HeadMusic::Rudiment::DurationComparison

  RhythmicUnit = HeadMusic::Rudiment::RhythmicUnit

  # A leading "triplet" or "5:4" word on a name.
  TUPLET_PREFIX = /\A(triplet|\d+\s*:\s*\d+)\s+(.+)\z/i

  # A word naming a tuplet anywhere but the leading ratio word, such as
  # "quintuplet eighth" or "eighth triplet", which the unanchored word parsers
  # would otherwise read as a plain value.
  TUPLET_WORD = /plets?(?![a-z])/i

  TIE = /\s+tied\s+to\s+/i

  attr_reader :unit, :dots, :tuplet_ratio

  delegate :name, to: :unit, prefix: true
  delegate :to_s, to: :name

  def self.get(identifier, tuplet: nil)
    value = from_identifier(identifier)
    tuplet ? value&.with_tuplet(tuplet) : value
  end

  def self.from_identifier(identifier)
    case identifier
    when HeadMusic::Rudiment::RhythmicValue
      identifier
    when HeadMusic::Rudiment::RhythmicUnit
      new(identifier)
    when Symbol, String
      NameReader.read(identifier.to_s.strip)
    end
  end

  private_class_method :from_identifier

  class << self
    delegate :from_words, :unit_from_words, :dots_from_words,
      to: "HeadMusic::Rudiment::RhythmicValue::NameReader"
  end

  def initialize(unit, dots: nil, tuplet: nil)
    @unit = HeadMusic::Rudiment::RhythmicUnit.get(unit) || raise(ArgumentError, "unknown rhythmic unit: #{unit.inspect}")
    @dots = [0, 1, 2, 3].include?(dots) ? dots : 0
    @tuplet_ratio = tuplet && tuplet_ratio_for(tuplet)
  end

  def unit_value
    unit.relative_value
  end

  def relative_value
    fraction.to_f
  end

  # The written length as a fraction of a whole note, leaving out its
  # tuplet ratio. A value with d dots spans (2^(d+1) - 1) / 2^d of its unit.
  def written_fraction
    Rational(unit.numerator, unit.denominator) * Rational((2**(dots + 1)) - 1, 2**dots)
  end

  # The length as an exact fraction of a whole note, under its ratio.
  def fraction
    tuplet_ratio ? written_fraction * tuplet_ratio.factor : written_fraction
  end

  # Rational, since a ratio such as 7:4 does not land on whole subticks.
  def exact_subticks
    fraction * HeadMusic::Rudiment::Rhythm::SUBTICKS_PER_WHOLE
  end

  # Rounded half up.
  def subticks
    exact_subticks.round
  end

  def tuplet?
    !tuplet_ratio.nil?
  end

  # The same value under a tuplet ratio, replacing any it had.
  def with_tuplet(tuplet)
    self.class.new(unit, dots: dots, tuplet: tuplet)
  end

  def total_value
    fraction.to_f
  end

  def multiplier
    (0..dots).reduce(0) { |sum, i| sum + 0.5**i }
  end

  def ticks
    (fraction * HeadMusic::Rudiment::Rhythm::PPQN * 4).to_f
  end

  def per_whole
    1.0 / relative_value
  end

  def name_modifier_prefix
    case dots
    when 1
      "dotted"
    when 2
      "double-dotted"
    when 3
      "triple-dotted"
    end
  end

  def name
    [tuplet_ratio&.name, name_modifier_prefix, unit_name].compact.join(" ")
  end

  def ==(other)
    case other
    when HeadMusic::Rudiment::RhythmicValue, String, Symbol
      to_s == other.to_s
    else
      false
    end
  end

  def eql?(other)
    other.is_a?(self.class) && self == other
  end

  def hash
    to_s.hash
  end

  def to_s
    name.tr("_", "-")
  end

  private

  def tuplet_ratio_for(tuplet)
    HeadMusic::Rudiment::TupletRatio.get(tuplet) || raise(ArgumentError, "unknown tuplet ratio: #{tuplet.inspect}")
  end
end
