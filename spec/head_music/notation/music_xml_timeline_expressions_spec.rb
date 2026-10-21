require "spec_helper"

# The timeline expressions MusicXML writes and reads back: tempo text beside
# a metronome mark and a sound, ramps as words with dashes, "a tempo",
# fermatas, and the meter symbols. MusicXML holds all of them but a
# fermata's stretch.
describe HeadMusic::Notation::MusicXML do
  def round_trip(flow)
    described_class.parse(described_class.render(flow))
  end

  {melody: TimelineExpressionFixtures.method(:melody), chorale: TimelineExpressionFixtures.method(:chorale)}.each do |name, fixture|
    it "round-trips the #{name}'s timeline" do
      original = fixture.call
      expect_same_timeline(original, round_trip(original))
    end

    it "writes the #{name} read back as it was written" do
      xml = described_class.render(fixture.call)
      expect(described_class.render(described_class.parse(xml))).to eq xml
    end
  end

  describe "converted by the MuseScore installed here", oracle: :musescore do
    {melody: TimelineExpressionFixtures.method(:melody), chorale: TimelineExpressionFixtures.method(:chorale)}.each do |name, fixture|
      it "reads the #{name}'s timeline back from MuseScore's conversion" do
        original = fixture.call
        expect_same_timeline(original, described_class.parse(MuseScore.convert(described_class.render(original))))
      end
    end
  end

  it "round-trips a ramp with no target ending where no other mark would end it, by its dashes" do
    flow = HeadMusic::Notation::ABC.parse("X:1\nM:4/4\nL:1/4\nK:C\nC D E F|G A B c|c B A G|\n")
    flow.add_tempo_ramp(from: "1:3", to: "2:2", text: "rall.")
    expect(HeadMusic::Notation::TempoMarks.new(flow).unreadable_ramps).not_to be_empty
    expect_same_timeline(flow, round_trip(flow))
  end

  it "round-trips a fermata on a tie's later link" do
    flow = HeadMusic::Notation::ABC.parse("X:1\nM:4/4\nL:1/4\nK:C\nC D E F-|F2 G2|\n")
    flow.add_fermata("2:1", :half)
    expect_same_timeline(flow, round_trip(flow))
  end
end
