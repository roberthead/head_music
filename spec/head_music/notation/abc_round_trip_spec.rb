require "spec_helper"

describe HeadMusic::Notation::ABC do
  describe "a round trip of articulations, ornaments, and dynamics" do
    let(:original) { MarkingFixtures.marked_melody }
    let(:round_tripped) { described_class.parse(described_class.render(original)) }

    it "keeps every marking and the dynamic in force at every note event" do
      expect_same_markings(original, round_tripped)
    end

    it "keeps the pitches and rhythm" do
      expect(round_tripped.voices.first.voice_events.map(&:to_s))
        .to eq original.voices.first.voice_events.map(&:to_s)
    end

    it "reads back what it wrote" do
      rendered = described_class.render(original)
      expect(described_class.render(described_class.parse(rendered))).to eq rendered
    end
  end
end
