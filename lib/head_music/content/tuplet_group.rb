# A module for musical content
module HeadMusic::Content; end

# A tuplet group says which notes and rests of a voice one tuplet bracket
# holds, from one position up to an exclusive end. Its values carry the ratio
# already; the group tells two triplets from one sextuplet, and gives the
# written unit its bracket counts in. It brackets tied links rather than
# whole events, so a triplet whose last note is tied over the beat is one
# group.
#
# It holds positions rather than voice events, as a span does, because a note
# placed on a rest replaces the rest's object.
class HeadMusic::Content::TupletGroup
  include Comparable

  attr_reader :voice, :from, :to, :unit, :ratio

  delegate :flow, to: :voice

  def self.label(ratio, from, to)
    [ratio&.to_a&.join(":"), "tuplet from #{from} to #{to}"].compact.join(" ")
  end

  def self.links_between(voice, from, to)
    HeadMusic::Content::ChainLink.between(voice, from, to)
  end

  def self.links_of(voice_event)
    HeadMusic::Content::ChainLink.of(voice_event)
  end

  # The written total over the ratio's actual count where that is one plain
  # or dotted value, as three triplet eighths count in eighths; otherwise the
  # largest value that divides every written fraction.
  def self.default_unit(written_fractions, ratio)
    single_value(written_fractions.sum / ratio.actual) ||
      single_value(written_fractions.reduce { |gcd, fraction| fraction_gcd(gcd, fraction) })
  end

  def self.single_value(fraction)
    value = HeadMusic::Notation::DottedDuration.rhythmic_value_for(fraction)
    value unless value.nil? || value.tied_value
  end

  def self.fraction_gcd(one, other)
    Rational(one.numerator.gcd(other.numerator), one.denominator.lcm(other.denominator))
  end
  private_class_method :single_value, :fraction_gcd

  def initialize(voice, from:, to:, unit: nil)
    @voice = voice
    @from = position_for(from)
    @to = position_for(to)
    raise ArgumentError, "the #{label} must end after it starts" unless @from < @to

    bracketing = Bracketing.new(voice, @from, @to)
    @ratio = bracketing.ratio
    @unit = unit ? unit_for(unit) : default_unit(bracketing.links)
    freeze
  end

  # The voice events with a link inside the group, in order.
  def voice_events
    links.map(&:voice_event).uniq
  end

  # The links inside the group, in order.
  def links
    Bracketing.links_inside(voice, from, to)
  end

  def covers?(position)
    from <= position && position < to
  end

  def overlaps?(other)
    from < other.to && other.from < to
  end

  # Ordered as spans are: by where a group starts, then ends.
  def <=>(other)
    return unless other.is_a?(self.class)

    [from, to] <=> [other.from, other.to]
  end

  def to_s
    label
  end

  def inspect
    "#<#{self.class.name} #{self}>"
  end

  def to_h
    {"from" => from.to_s, "to" => to.to_s, "unit" => unit.to_s}
  end

  private

  def label
    self.class.label(ratio, from, to)
  end

  def default_unit(links)
    self.class.default_unit(links.map { |link| link.rhythmic_value.written_fraction }, ratio)
  end

  def unit_for(identifier)
    unit = HeadMusic::Rudiment::RhythmicValue.get(identifier)
    unless unit&.unit && !unit.tied_value && !unit.tuplet?
      raise ArgumentError, "the #{label} needs a plain or dotted value for its unit, not #{identifier.inspect}"
    end

    unit
  end

  def position_for(position)
    HeadMusic::Content::Position.for_flow(voice.flow, position)
  end
end
