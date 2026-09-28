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

  describe "a round trip of slurs and phrases" do
    def round_trip(flow)
      described_class.parse(described_class.render(flow))
    end

    it "keeps the melody's music" do
      expect_abc_round_trip(MarkingFixtures.spanned_melody)
    end

    it "keeps where each slur starts and ends, and brings the phrase back as a slur drawn in to its notes" do
      expect(span_summary(round_trip(MarkingFixtures.spanned_melody))).to eq [[
        "slur from 1:1:000 to 1:3:000", "slur from 1:1:000 to 4:2:000", "slur from 2:1:000 to 2:4:000",
        "slur from 2:2:000 to 2:3:000", "slur from 3:4:000 to 4:2:000"
      ]]
    end

    it "brings back touching slurs with the second starting a note later" do
      expect(span_summary(round_trip(MarkingFixtures.touching_slurs)))
        .to eq [["slur from 1:1:000 to 1:3:000", "slur from 1:4:000 to 2:1:000"]]
    end

    it "reads back what it wrote" do
      rendered = described_class.render(MarkingFixtures.spanned_melody)
      expect(described_class.render(described_class.parse(rendered))).to eq rendered
    end
  end
end
