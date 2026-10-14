# A module for visual music notation
module HeadMusic::Notation; end

# A hairpin cut into touching pieces wherever a dynamic falls strictly inside
# it. LilyPond ends a hairpin at a level or accent in its context, and
# Verovio drops a kern hairpin that one interrupts, so those writers draw the
# pieces, which meet at the dynamic, rather than the whole.
module HeadMusic::Notation::HairpinSegments
  def self.split(hairpins, cuts)
    cuts = cuts.uniq.sort
    hairpins.flat_map do |hairpin|
      inside = cuts.select { |cut| hairpin.from < cut && cut < hairpin.to }
      [hairpin.from, *inside, hairpin.to].each_cons(2).map do |from, to|
        HeadMusic::Content::Span.new(hairpin.flow, hairpin.kind, from: from, to: to)
      end
    end
  end
end
