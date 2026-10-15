# A module for visual music notation
module HeadMusic::Notation; end

# Where a curve ends among the written pieces of the event at its end. A
# note's pieces are tied, so it ends on the last; a rest's pieces are rests
# of their own, so it ends on the first.
module HeadMusic::Notation::SpanEnds
  def self.closing_piece?(voice_event, first:, last:)
    voice_event.rest? ? first : last
  end
end
