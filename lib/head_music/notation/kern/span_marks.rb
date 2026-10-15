# A namespace for **kern rendering helpers
module HeadMusic::Notation::Kern
  # The slur and phrase marks of one voice's spans, by the position of the
  # voice event that carries them.
  #
  # A reader pairs each close with the latest open of its kind, so spans of
  # a kind nest cleanly at one level. A span that would cross one there
  # moves to the next elision level, written with an & for each level, as
  # "&(" for a slur overlapping another.
  #
  # A span from grace notes opens on the first of them, which the reader
  # takes before the closes of the note they lead to, so it counts as
  # opening before any span that ends or starts on that note.
  class SpanMarks
    BRACKETS = {slur: %w[( )], phrase: %w[{ }]}.freeze

    def initialize(voice)
      @flow = voice.flow
      @opens = Hash.new { |hash, key| hash[key] = [] }
      @grace_opens = Hash.new { |hash, key| hash[key] = [] }
      @closes = Hash.new { |hash, key| hash[key] = [] }
      levels(voice.spans.select(&:curve?)).each do |span, level|
        opening, closing = BRACKETS.fetch(span.kind)
        (span.from_grace? ? @grace_opens : @opens)[span.from.to_s] << "#{"&" * level}#{opening}"
        @closes[span.to.to_s] << "#{"&" * level}#{closing}"
      end
    end

    def opens_at(position)
      @opens.fetch(key(position), []).join
    end

    def grace_opens_at(position)
      @grace_opens.fetch(key(position), []).join
    end

    def closes_at(position)
      @closes.fetch(key(position), []).join
    end

    private

    def key(position)
      HeadMusic::Content::Position.new(@flow, position.to_s).to_s
    end

    # Longer spans open first, so a span starting where another does nests
    # inside it. Spans from grace notes open before the rest, and phrases
    # before slurs.
    def levels(spans)
      ordered = spans.sort { |one, other| [one.from, grace_rank(one), rank(one), other.to] <=> [other.from, grace_rank(other), rank(other), one.to] }
      ordered.each_with_object([]) do |span, placed|
        placed << [span, level_for(span, placed)]
      end
    end

    def grace_rank(span)
      span.from_grace? ? 0 : 1
    end

    def rank(span)
      (span.kind == :phrase) ? 0 : 1
    end

    def level_for(span, placed)
      (0..).find do |level|
        enclosing = placed.select do |other, other_level|
          other_level == level && other.kind == span.kind && open_at_start?(other, span)
        end
        enclosing.empty? || span.to <= enclosing.last.first.to
      end
    end

    # A span ending on the note a grace span starts before is still open
    # when the grace span opens.
    def open_at_start?(other, span)
      span.from_grace? ? other.to >= span.from : other.to > span.from
    end
  end
end
