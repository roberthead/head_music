# A namespace for ABC-notation parsing helpers
module HeadMusic::Notation::ABC
  # Writes a voice's tuplet brackets as "(p:q:r" markers. A segment holding a
  # tuplet value is written as pieces, one token each: its consecutive links
  # of one ratio in one bracket. A bracket's r counts its pieces, since ABC
  # counts notes, and the short "(3" or "(2" is written where it means the
  # same in any meter.
  class TupletWriter
    Piece = Data.define(:links, :marker)

    SHORT_ACTUALS = [2, 3].freeze

    def initialize(voice, segments)
      brackets = voice ? HeadMusic::Notation::TupletBrackets.for(voice, segments, error_class: RenderError) : []
      @brackets = {}.compare_by_identity
      brackets.each do |bracket|
        bracket.links.each { |link| (@brackets[link.segment] ||= {})[link.index] = bracket }
      end
      @counts = Hash.new(0).compare_by_identity
      segments.each do |segment|
        next unless segment.voice_event.rhythmic_duration.tuplet?

        split(segment).each { |_, _, bracket| @counts[bracket] += 1 if bracket }
      end
    end

    # Nil for a segment with no tuplet value, which is written whole.
    def pieces(segment)
      return unless segment.voice_event.rhythmic_duration.tuplet?

      split(segment).map do |index, links, bracket|
        Piece.new(links, opens?(bracket, segment, index) ? marker(bracket) : "")
      end
    end

    private

    # Each piece as [the index of its first link, its links, its bracket].
    def split(segment)
      chain = segment.rhythmic_duration!(RenderError).values
      brackets = @brackets.fetch(segment, {})
      chain.each_index.chunk_while do |index, following|
        chain[index].tuplet_ratio == chain[following].tuplet_ratio && brackets[index].equal?(brackets[following])
      end.map { |indexes| [indexes.first, indexes.map { |index| chain[index] }, brackets[indexes.first]] }
    end

    def opens?(bracket, segment, index)
      return false unless bracket

      first = bracket.first
      first.segment.equal?(segment) && first.index == index
    end

    def marker(bracket)
      ratio = bracket.ratio
      actual = ratio.actual
      normal = ratio.normal
      count = @counts.fetch(bracket)
      return "(#{actual}" if short?(actual, normal, count)

      "(#{actual}:#{normal}:#{count}"
    end

    def short?(actual, normal, count)
      SHORT_ACTUALS.include?(actual) && count == actual && TupletMarker.default_normal(actual, compound: false) == normal
    end
  end
end
