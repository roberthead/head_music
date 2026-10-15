# A module for music rudiments
module HeadMusic::Rudiment; end

# A tuplet ratio says how many notes (actual) take the time of how many
# others of the same written value (normal), as three eighths in the time of
# two. It is never reduced: a sextuplet of 6:4 is not two triplets of 3:2.
class HeadMusic::Rudiment::TupletRatio
  PATTERN = /\A\s*(\d+)\s*:\s*(\d+)\s*\z/
  NAMED = {"triplet" => [3, 2]}.freeze

  attr_reader :actual, :normal

  private_class_method :new

  # Nil for anything that does not name a ratio. A ratio that names no tuplet,
  # such as 1:1 or 0:2, raises instead.
  def self.get(identifier)
    case identifier
    when self
      identifier
    when Array
      numbers = identifier
      fetch(*numbers) if numbers.length == 2 && numbers.all?(Integer)
    when String, Symbol
      numbers = numbers_from(identifier.to_s.strip.downcase)
      fetch(*numbers) if numbers
    end
  end

  def self.numbers_from(text)
    return NAMED[text] if NAMED.key?(text)

    match = text.match(PATTERN)
    match && [match[1].to_i, match[2].to_i]
  end

  def self.fetch(actual, normal)
    unless actual.positive? && normal.positive? && actual != normal
      raise ArgumentError, "#{actual}:#{normal} is not a tuplet ratio"
    end

    @ratios ||= {}
    @ratios[[actual, normal]] ||= new(actual, normal)
  end

  private_class_method :numbers_from, :fetch

  def initialize(actual, normal)
    @actual = actual
    @normal = normal
    freeze
  end

  # The share of its written value that a note under this ratio sounds.
  def factor
    Rational(normal, actual)
  end

  # Only 3:2 has a name every reader agrees on; "quintuplet" or "duplet"
  # could mean more than one ratio.
  def name
    (NAMED.key([actual, normal]) || to_a.join(":")).dup
  end

  alias_method :to_s, :name

  def to_a
    [actual, normal]
  end

  def ==(other)
    other.is_a?(self.class) && to_a == other.to_a
  end

  alias_method :eql?, :==

  def hash
    to_a.hash
  end

  def inspect
    "#<#{self.class.name} #{to_a.join(":")}>"
  end
end
