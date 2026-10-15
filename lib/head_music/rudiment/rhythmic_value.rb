# A module for musical content
module HeadMusic::Rudiment; end

# A rhythmic value is a duration composed of a rhythmic unit, any number of
# dots, an optional tuplet ratio, and a tied value. Each link of a tied chain
# carries its own ratio.
class HeadMusic::Rudiment::RhythmicValue
  include Comparable

  RhythmicUnit = HeadMusic::Rudiment::RhythmicUnit

  # A leading "triplet" or "5:4" word on one link of a name.
  TUPLET_PREFIX = /\A(triplet|\d+\s*:\s*\d+)\s+(.+)\z/i

  # A leading word naming a tuplet without its ratio, such as "quintuplet",
  # which the unanchored word parsers would otherwise read as a plain value.
  UNNAMED_TUPLET_PREFIX = /\A\w*(?<!tri)plets?\b/i

  attr_reader :unit, :dots, :tied_value, :tuplet_ratio

  delegate :name, to: :unit, prefix: true
  delegate :to_s, to: :name

  # With a tuplet ratio, every link of the value carries it.
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
      from_name(identifier.to_s.strip)
    end
  end

  def self.from_name(name)
    # Handle tied values first, so "half tied to eighth" round-trips through #to_s
    from_tied_words(name) || from_tuplet_words(name) || from_plain_name(name)
  end

  # Strips a leading ratio word before the other parsers see it, since they
  # match a unit anywhere and would read "triplet" as triple-dotted.
  def self.from_tuplet_words(name)
    match = name.match(TUPLET_PREFIX)
    return unless match

    ratio = ratio_from_word(match[1])
    value = ratio && from_plain_name(match[2].strip)
    value.with_tuplet(ratio) if value&.unit && !value.tuplet?
  end

  def self.ratio_from_word(word)
    HeadMusic::Rudiment::TupletRatio.get(word)
  rescue ArgumentError
    nil
  end

  def self.from_plain_name(name)
    return if name.match?(TUPLET_PREFIX) || name.match?(UNNAMED_TUPLET_PREFIX)

    # Then try the new parser which handles all formats
    parsed = Parser.parse(name)
    return parsed if parsed

    # Then try the word-based approach as fallback
    begin
      from_words(HeadMusic::Utilities::Case.to_snake_case(name))
    rescue
      nil
    end
  end

  private_class_method :from_identifier, :from_name, :from_tuplet_words, :ratio_from_word, :from_plain_name

  # Splits on the first " tied to " and recurses on the remainder,
  # so chained ties ("half tied to eighth tied to sixteenth") nest naturally.
  def self.from_tied_words(identifier)
    head, tail = identifier.split(/\s+tied\s+to\s+/, 2)
    return nil unless tail

    head_value = get(head)
    tied_value = get(tail)
    return nil unless head_value && tied_value && !head_value.tied_value

    new(head_value.unit, dots: head_value.dots, tied_value: tied_value, tuplet: head_value.tuplet_ratio)
  end

  def self.from_words(identifier)
    new(unit_from_words(identifier), dots: dots_from_words(identifier))
  end

  def self.unit_from_words(identifier)
    identifier.gsub(/^\w*dotted_/, "")
  end

  def self.dots_from_words(identifier)
    return 0 unless identifier.match?(/dotted/)

    modifier, = identifier.split(/_*dotted_*/)
    case modifier
    when /tripl\w/
      3
    when /doubl\w/
      2
    else
      1
    end
  end

  def initialize(unit, dots: nil, tied_value: nil, tuplet: nil)
    @unit = HeadMusic::Rudiment::RhythmicUnit.get(unit)
    @dots = [0, 1, 2, 3].include?(dots) ? dots : 0
    @tied_value = tied_value
    @tuplet_ratio = tuplet && tuplet_ratio_for(tuplet)
  end

  def unit_value
    unit.relative_value
  end

  # This link alone, as a fraction of a whole note, under its ratio.
  def relative_value
    link_fraction.to_f
  end

  # This link's written length as a fraction of a whole note, leaving out its
  # tuplet ratio. A value with d dots spans (2^(d+1) - 1) / 2^d of its unit.
  def written_fraction
    Rational(unit.numerator, unit.denominator) * Rational((2**(dots + 1)) - 1, 2**dots)
  end

  # The whole chain as an exact fraction of a whole note, ratios included.
  def fraction
    @fraction ||= link_fraction + (tied_value ? tied_value.fraction : 0)
  end

  # Rational, since a ratio such as 7:4 does not land on whole subticks.
  def exact_subticks
    fraction * HeadMusic::Rudiment::Rhythm::SUBTICKS_PER_WHOLE
  end

  # Rounded half up, once over the whole chain.
  def subticks
    exact_subticks.round
  end

  def tuplet?
    tied_chain.any?(&:tuplet_ratio)
  end

  # The ratio every link carries, or nil when they differ or carry none.
  def uniform_tuplet_ratio
    ratios = tied_chain.map(&:tuplet_ratio).uniq
    ratios.first if ratios.length == 1
  end

  # The same value with a tuplet ratio on every link, replacing any it had.
  def with_tuplet(tuplet)
    self.class.new(unit, dots: dots, tied_value: tied_value&.with_tuplet(tuplet), tuplet: tuplet)
  end

  # The value and every link tied after it, in order. A value with no
  # tied_value is a chain of one.
  def tied_chain
    chain = [self]
    chain << chain.last.tied_value while chain.last.tied_value
    chain
  end

  def total_value
    fraction.to_f
  end

  # A new value with `tail` tied on at the deep end of this value's chain,
  # so "half tied to eighth" gains a further "tied to quarter". Values are
  # immutable, so each link is rebuilt.
  def append_tied(tail)
    inner = tied_value ? tied_value.append_tied(tail) : tail
    self.class.new(unit, dots: dots, tied_value: inner, tuplet: tuplet_ratio)
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

  def single_value_name
    [tuplet_ratio&.name, name_modifier_prefix, unit_name].compact.join(" ")
  end

  def name
    if tied_value
      [single_value_name, tied_value.name].compact.join(" tied to ")
    else
      single_value_name
    end
  end

  def ==(other)
    to_s == other.to_s
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

  def <=>(other)
    total_value <=> other.total_value
  end

  private

  def link_fraction
    tuplet_ratio ? written_fraction * tuplet_ratio.factor : written_fraction
  end

  def tuplet_ratio_for(tuplet)
    HeadMusic::Rudiment::TupletRatio.get(tuplet) || raise(ArgumentError, "unknown tuplet ratio: #{tuplet.inspect}")
  end
end
