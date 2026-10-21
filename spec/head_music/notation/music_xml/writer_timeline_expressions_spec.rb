require "spec_helper"

describe HeadMusic::Notation::MusicXML::Writer do
  def document(flow)
    REXML::Document.new(described_class.new(flow).to_s)
  end

  # The notes and rests marked with a fermata, by part and measure.
  def fermata_notes(flow)
    REXML::XPath.match(document(flow), "//note[notations/fermata]").map do |note|
      measure = note.parent
      step = REXML::XPath.first(note, "pitch/step")&.text
      octave = REXML::XPath.first(note, "pitch/octave")&.text
      [measure.parent.attributes["id"], measure.attributes["number"], step ? "#{step}#{octave}" : "rest", REXML::XPath.first(note, "type")&.text]
    end
  end

  def abc(body, meter: "4/4")
    HeadMusic::Notation::ABC.parse("X:1\nT:Fermatas\nM:#{meter}\nL:1/4\nK:C\n#{body}")
  end

  def times(flow)
    REXML::XPath.match(document(flow), "//time").map { |time| time.attributes["symbol"] }
  end

  describe "fermatas" do
    it "marks the note in every voice sounding where a fermata begins" do
      expect(fermata_notes(TimelineExpressionFixtures.chorale)).to eq [
        ["P1", "2", "C5", "quarter"], ["P1", "4", "D5", "half"], ["P2", "2", "A3", "eighth"], ["P2", "4", "D3", "half"]
      ]
    end

    it "marks a rest" do
      expect(fermata_notes(TimelineExpressionFixtures.melody).last).to eq ["P1", "6", "rest", "half"]
    end

    it "marks a note held from before the fermata" do
      flow = abc("V:1\ne e e e|\nV:2\nC,4|\n")
      flow.add_fermata("1:4", :quarter)
      expect(fermata_notes(flow)).to eq [["P1", "1", "E5", "quarter"], ["P2", "1", "C3", "whole"]]
    end

    it "marks only the written piece of a tied note sounding where the fermata begins" do
      flow = abc("C2 D2-|D2 E2|\n")
      flow.add_fermata("2:1", :half)
      expect(fermata_notes(flow)).to eq [["P1", "2", "D4", "half"]]
    end

    it "marks the whole-measure rest of a voice silent through the bar" do
      flow = abc("V:1\ne4|f4|\nV:2\nC,4|\n")
      flow.add_fermata("2:1", :whole)
      rests = REXML::XPath.match(document(flow), %(//part[@id="P2"]/measure[@number="2"]/note[rest[@measure="yes"]]/notations/fermata))
      expect([fermata_notes(flow), rests.length]).to eq [[["P1", "2", "F5", "whole"], ["P2", "2", "rest", nil]], 1]
    end
  end

  describe "meter symbols" do
    it "writes common and cut time, and a change of the symbol alone" do
      flow = abc("C4|C4|C2|\n", meter: "C")
      flow.change_meter(2, HeadMusic::Rudiment::Meter.get("4/4"))
      flow.change_meter(3, HeadMusic::Rudiment::Meter.cut_time)
      expect(times(flow)).to eq ["common", nil, "cut"]
    end
  end
end
