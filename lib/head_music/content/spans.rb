# A module for musical content
module HeadMusic::Content; end

# The spans of a voice, and later of a part, kept in order. Spans of a kind
# may nest or overlap, since a score can say either; only the same span
# twice is refused. What a span's ends must sit on is its owner's check.
class HeadMusic::Content::Spans
  include Enumerable

  delegate :each, :empty?, :length, to: :@spans

  def initialize
    @spans = []
  end

  def add(span)
    index = @spans.bsearch_index { |existing| existing >= span } || @spans.length
    raise ArgumentError, "the #{span} is already there" if @spans[index] == span

    @spans.insert(index, span)
    span
  end

  def to_a
    @spans.dup
  end
end
