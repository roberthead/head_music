# A module for musical content
module HeadMusic::Content; end

# A span is a marking that runs from one position to a later one, such as a
# slur or a phrase mark. It holds positions rather than voice events: a voice
# never moves or removes an event, and a note placed on a rest keeps the
# rest's position and value, so a span checked when it is added stays true.
class HeadMusic::Content::Span
  include Comparable

  attr_reader :flow, :span_kind, :from, :to

  delegate :name_key, to: :span_kind

  def initialize(flow, kind, from:, to:)
    @flow = flow
    @span_kind = span_kind_for(kind)
    @from = position_for(from)
    @to = position_for(to)
    raise ArgumentError, "a #{name_key} must end after it starts, from #{@from} to #{@to}" unless @from < @to
  end

  def kind
    name_key.to_sym
  end

  # Ordered by where a span starts, then ends, then by the catalog's order of
  # kinds, so a voice's spans always serialize the same way.
  def <=>(other)
    return unless other.is_a?(self.class)

    [from, to, kind_index] <=> [other.from, other.to, other.kind_index]
  end

  def to_s
    "#{name_key} from #{from} to #{to}"
  end

  def inspect
    "#<#{self.class.name} #{self}>"
  end

  def to_h
    {"kind" => name_key, "from" => from.to_s, "to" => to.to_s}
  end

  protected

  def kind_index
    HeadMusic::Rudiment::SpanKind.all.index(span_kind)
  end

  private

  def span_kind_for(identifier)
    span_kind = HeadMusic::Rudiment::SpanKind.get(identifier)
    raise ArgumentError, "unknown span kind: #{identifier.inspect}" unless span_kind

    span_kind
  end

  def position_for(position)
    return HeadMusic::Content::Position.new(flow, position) unless position.is_a?(HeadMusic::Content::Position)
    raise ArgumentError, "position belongs to a different flow" unless position.flow.equal?(flow)

    position
  end
end
