# A module for musical content
module HeadMusic::Content; end

# The spans of a voice or a part, kept in order. Curves of a kind may nest or
# overlap, since a score can say either, but one dynamics line cannot grow and
# shrink at once, so its hairpins may only touch. The same span twice is
# refused. What a span's ends must sit on is its owner's check.
class HeadMusic::Content::Spans
  include Enumerable

  delegate :each, :empty?, :length, to: :@spans

  # Spans that have begun latest, then end soonest, come first.
  def self.innermost_first(spans)
    spans.sort { |one, other| [other.from, one.to] <=> [one.from, other.to] }
  end

  def initialize
    @spans = []
  end

  def add(span)
    index = @spans.bsearch_index { |existing| existing >= span } || @spans.length
    raise ArgumentError, "the #{span} is already there" if @spans[index] == span

    overlapped = overlapped_hairpin(span)
    raise ArgumentError, "the #{span} overlaps the #{overlapped}" if overlapped

    @spans.insert(index, span)
    span
  end

  # The spans that have begun by a position and not yet run out, innermost
  # first. Where a span runs out is its owner's to say.
  def covering(position)
    self.class.innermost_first(@spans.select { |span| span.from <= position && position < yield(span) })
  end

  def to_a
    @spans.dup
  end

  private

  def overlapped_hairpin(span)
    return unless span.hairpin?

    @spans.find { |existing| existing.hairpin? && existing.from < span.to && span.from < existing.to }
  end
end
