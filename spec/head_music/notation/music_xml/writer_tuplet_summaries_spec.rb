require "spec_helper"

# MusicXML has no reader yet, so its tuplets, grace notes, and divisions are
# read back from the document as summaries and set beside the flow's.
describe HeadMusic::Notation::MusicXML::Writer do
  TupletFixtures.all.each do |name|
    it "writes the tuplets, grace notes, and timing of the #{name} fixture" do
      flow = TupletFixtures.public_send(name)
      expect(musicxml_summaries(described_class.new(flow).to_s)).to eq expected_musicxml_summaries(flow)
    end
  end

  TupletGenerator::SEEDS.each do |seed|
    it "writes the tuplets, grace notes, and timing of seed #{seed}" do
      flow = TupletGenerator.flow(seed)
      expect(musicxml_summaries(described_class.new(flow).to_s)).to eq expected_musicxml_summaries(flow)
    end
  end

  describe "the summaries" do
    let(:flow) { TupletFixtures.tuplets_in_two_voices }
    let(:xml) { described_class.new(flow).to_s }

    it "find every bracket of both voices" do
      expect(musicxml_tuplet_summary(xml)[:brackets].map { |bracket| bracket[1, 3] }).to eq [
        ["1", [1, 0], [1, 15]], ["1", [1, 15], [1, 30]], ["2", [1, 30], [1, 60]]
      ]
    end

    it "report a bracket that never stops" do
      broken = xml.sub(%(<tuplet type="stop" number="2"/>), "")
      expect(musicxml_tuplet_summary(broken)[:problems]).to include(/never stops/)
    end

    it "report a tuplet note under no bracket" do
      broken = xml.sub(%(<tuplet type="start" number="1"/>), "")
      expect(musicxml_tuplet_summary(broken)[:problems]).to include(/under no bracket/)
    end

    it "report a grace note written with a duration" do
      graced = described_class.new(TupletFixtures.grace_notes_before_downbeat).to_s
      broken = graced.sub(%(<grace slash="yes"/>), %(<grace slash="yes"/><duration>1</duration>))
      expect(musicxml_grace_summary(broken)[:problems]).to include(/has a duration/)
    end

    it "read each grace note's pitches, value, slash, ties, articulations, and slur" do
      graced = described_class.new(TupletFixtures.grace_notes_before_downbeat).to_s
      expect(musicxml_grace_summary(graced)[:runs].last).to eq [
        "P1", nil, [3, 0], [[["D4"], "16th", 0, false, [], [], true], [["C4"], "16th", 0, false, ["C4"], [], false]]
      ]
    end
  end
end
