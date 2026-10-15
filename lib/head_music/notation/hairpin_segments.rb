# A module for visual music notation
module HeadMusic::Notation; end

# A hairpin cut into touching pieces wherever a dynamic falls strictly inside
# it. LilyPond ends a hairpin at a level or accent in its context, and
# Verovio drops a kern hairpin that one interrupts, so those writers draw the
# pieces, which meet at the dynamic, rather than the whole.
module HeadMusic::Notation::HairpinSegments
  def self.split(hairpins, cuts)
    cuts = cuts.uniq.sort
    hairpins.flat_map { |hairpin| pieces(hairpin, cuts) }
  end

  # +cuts+ sorted and without duplicates.
  def self.pieces(hairpin, cuts)
    first = cuts.bsearch_index { |cut| cut > hairpin.from } || cuts.length
    inside = cuts[first..].take_while { |cut| cut < hairpin.to }
    [hairpin.from, *inside, hairpin.to].each_cons(2).map do |from, to|
      HeadMusic::Content::Span.new(hairpin.flow, hairpin.kind, from: from, to: to)
    end
  end
end
