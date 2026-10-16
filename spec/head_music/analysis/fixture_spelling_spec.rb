require "spec_helper"

# The written fixtures, stripped to key numbers and respelled, against their
# written spelling: by the key signatures in force, and under inferred keys.
describe "HeadMusic::Analysis::PitchSpeller" do
  fixtures = File.expand_path("../../fixtures/notation", __dir__)
  sharp_for_flat = ["5:3:000 voice 1.1 C♯5 → D♭5"]

  {
    "Speed the Plough" => [-> { HeadMusic::Notation::ABC.parse(ABCFixtures::SPEED_THE_PLOUGH) }, 52, 0, [], []],
    "Chromatic Air" => [-> { HeadMusic::Notation::ABC.parse(ABCFixtures::CHROMATIC_AIR) }, 22, 0, [], []],
    "bach_invention_01.ly" => [-> { HeadMusic::Notation::LilyPond.parse(File.read(File.join(fixtures, "lily_pond", "bach_invention_01.ly"))) }, 458, 0, [], []],
    "articulations_ornaments_dynamics.krn" => [nil, 24, 0, sharp_for_flat, sharp_for_flat],
    "grace_notes.krn" => [nil, 9, 7, [], []],
    "hairpins.krn" => [nil, 16, 0, [], []],
    "piano_splits.krn" => [nil, 18, 0, [], []],
    "satb_chorale.krn" => [nil, 48, 0, [], []],
    "tuplets.krn" => [nil, 49, 0, [], []]
  }.each do |name, (reader, count, grace_count, given, inferred)|
    context "with #{name}" do
      let(:flow) { reader ? reader.call : HeadMusic::Notation::Kern.parse(File.read(File.join(fixtures, "kern", name))) }

      it "respells #{given.length} of #{count} notes by the key signatures in force" do
        expect(SpellingEvaluation.differences(flow, key: nil)).to eq(count: count, grace_count: grace_count, differences: given)
      end

      it "respells #{inferred.length} of #{count} notes under inferred keys" do
        expect(SpellingEvaluation.differences(flow, key: :infer)).to eq(count: count, grace_count: grace_count, differences: inferred)
      end
    end
  end

  it "spells the marks duet's one miss by the sonority rule" do
    flow = HeadMusic::Notation::Kern.parse(File.read(File.join(fixtures, "kern", "articulations_ornaments_dynamics.krn")))
    expect(SpellingEvaluation.misses(flow, key: nil)[:misses].map { |miss| [miss.written, miss.spelled, miss.rule, miss.grace?] })
      .to eq [["C♯5", "D♭5", :sonority, false]]
  end
end
