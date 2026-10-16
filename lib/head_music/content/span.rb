# A module for musical content
module HeadMusic::Content; end

# A span is a marking that runs from one position to a later one, such as a
# slur or a phrase mark. It holds positions rather than voice events: a voice
# never moves or removes an event, and a note placed on a rest keeps the
# rest's position and value, so a span checked when it is added stays true.
class HeadMusic::Content::Span
  include Comparable

  attr_reader :flow, :span_kind, :from, :to, :from_grace

  delegate :name_key, :curve?, :hairpin?, to: :span_kind

  # A span from_grace starts on the first grace note of the note event at
  # from, so it may end on that same event, as a slur from a grace note to its
  # main note does. A slur that ends on a grace note ends on its main note.
  def initialize(flow, kind, from:, to:, from_grace: false)
    @flow = flow
    @span_kind = span_kind_for(kind)
    @from = position_for(from)
    @to = position_for(to)
    @from_grace = from_grace ? true : false
    raise ArgumentError, "a #{name_key} cannot start on grace notes; only a slur or phrase can" if @from_grace && !curve?
    return if @from < @to || (@from_grace && @from == @to)

    raise ArgumentError, "a #{name_key} must end after it starts, from #{@from} to #{@to}"
  end

  alias_method :from_grace?, :from_grace

  def kind
    name_key.to_sym
  end

  # Ordered by where a span starts, with one from the grace notes there
  # first, then ends, then by the catalog's order of kinds, so a voice's spans
  # always serialize the same way.
  def <=>(other)
    return unless other.is_a?(self.class)

    sort_key <=> other.sort_key
  end

  def to_s
    "#{name_key} from #{"the grace notes before " if from_grace?}#{from} to #{to}"
  end

  def inspect
    "#<#{self.class.name} #{self}>"
  end

  def to_h
    hash = {"kind" => name_key, "from" => from.to_s, "to" => to.to_s}
    hash["from_grace"] = true if from_grace?
    hash
  end

  protected

  def sort_key
    [from, from_grace? ? 0 : 1, to, kind_index]
  end

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
    HeadMusic::Content::Position.for_flow(flow, position)
  end
end
