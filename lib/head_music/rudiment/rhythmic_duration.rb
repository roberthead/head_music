# A module for music rudiments
module HeadMusic::Rudiment; end

# A rhythmic duration is how long a note or rest lasts, written as one
# rhythmic value or as several tied together.
class HeadMusic::Rudiment::RhythmicDuration
  include HeadMusic::Rudiment::DurationComparison

  RhythmicValue = HeadMusic::Rudiment::RhythmicValue

  attr_reader :values, :fraction

  # With a tuplet ratio, every value carries it.
  def self.get(identifier, tuplet: nil)
    duration = from_identifier(identifier)
    tuplet ? duration&.with_tuplet(tuplet) : duration
  end

  def self.from_identifier(identifier)
    case identifier
    when HeadMusic::Rudiment::RhythmicDuration
      identifier
    when RhythmicValue
      new([identifier])
    when HeadMusic::Rudiment::RhythmicUnit
      new([RhythmicValue.new(identifier)])
    when Symbol, String
      from_name(identifier.to_s.strip)
    end
  end

  def self.from_name(name)
    values = name.split(RhythmicValue::TIE).map { |piece| RhythmicValue.get(piece) }
    new(values) if values.any? && values.all?
  end

  private_class_method :from_identifier, :from_name

  def initialize(values)
    raise ArgumentError, "a rhythmic duration needs at least one rhythmic value" if values.empty?
    raise ArgumentError, "a rhythmic duration holds only rhythmic values" unless values.all?(RhythmicValue)

    @values = values.dup.freeze
    @fraction = @values.sum(&:fraction)
    freeze
  end

  # The lone value of an untied duration, or nil when it is tied.
  def single_value
    values.first if values.length == 1
  end

  # Rational, since a ratio such as 7:4 does not land on whole subticks.
  def exact_subticks
    fraction * HeadMusic::Rudiment::Rhythm::SUBTICKS_PER_WHOLE
  end

  # Rounded half up, once over the whole duration rather than once per value.
  def subticks
    exact_subticks.round
  end

  def ticks
    (fraction * HeadMusic::Rudiment::Rhythm::PPQN * 4).to_f
  end

  def total_value
    fraction.to_f
  end

  def tuplet?
    values.any?(&:tuplet_ratio)
  end

  # The ratio every value carries, or nil when they differ or carry none.
  def uniform_tuplet_ratio
    ratios = values.map(&:tuplet_ratio).uniq
    ratios.first if ratios.length == 1
  end

  # The same duration with a tuplet ratio on every value, replacing any it had.
  def with_tuplet(tuplet)
    self.class.new(values.map { |value| value.with_tuplet(tuplet) })
  end

  # A new duration with a value, or another duration's values, tied on at the end.
  def tied_to(tail)
    tail_duration = self.class.get(tail) || raise(ArgumentError, "unknown rhythmic duration: #{tail.inspect}")
    self.class.new(values + tail_duration.values)
  end

  def name
    values.join(" tied to ")
  end

  alias_method :to_s, :name

  def ==(other)
    case other
    when HeadMusic::Rudiment::RhythmicDuration, String, Symbol
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
end
