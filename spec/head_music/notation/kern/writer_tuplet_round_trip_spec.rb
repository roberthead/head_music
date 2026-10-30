require "spec_helper"

# Tuplets and grace notes written to kern and read back; see
# spec/support/kern_round_trip.rb for what the comparison leaves out.
describe HeadMusic::Notation::Kern::Writer do
  def round_trip(flow)
    HeadMusic::Notation::Kern.parse(described_class.new(flow).to_s)
  end

  describe "the tuplet fixtures" do
    TupletFixtures.all.each do |name|
      it "round-trips #{name}" do
        expect_kern_tuplet_round_trip(TupletFixtures.public_send(name))
      end
    end

    it "keeps a quintuplet, a septuplet, a triplet across a barline, and a triplet ending in a mixed chain as groups" do
      flows = %i[quintuplet septuplet_crossing_barline tuplet_crossing_barline triplet_tied_out].map { |name| TupletFixtures.public_send(name) }
      expect(flows.map { |flow| tuplet_summary(round_trip(flow)) }).to eq flows.map { |flow| tuplet_summary(flow) }
    end

    it "reads a sextuplet back as two triplets" do
      reparsed = round_trip(TupletFixtures.sextuplet)
      expect(tuplet_summary(reparsed)).to eq [[["1:1:000", "1:1:480", "triplet", "sixteenth"], ["1:1:480", "1:2:000", "triplet", "sixteenth"]]]
    end

    it "reads a duplet back as dotted values" do
      reparsed = round_trip(TupletFixtures.duplet_in_six_eight)
      expect(reparsed.voices.first.voice_events.first(2).map { |voice_event| voice_event.rhythmic_duration.to_s }).to eq ["dotted eighth", "dotted eighth"]
    end
  end

  describe "the kern fixtures" do
    %w[tuplets grace_notes].each do |name|
      it "reads #{name}.krn back to itself from what it writes" do
        flow = HeadMusic::Notation::Kern.parse(File.read(File.expand_path("../../../fixtures/notation/kern/#{name}.krn", __dir__)))
        expect(round_trip(flow).to_h).to eq flow.to_h
      end
    end
  end

  describe "generated flows" do
    TupletGenerator::SEEDS.each do |seed|
      it "round-trips seed #{seed}" do
        expect_kern_tuplet_round_trip(TupletGenerator.flow(seed))
      end
    end
  end
end
