require "spec_helper"

describe HeadMusic::Notation::MusicXML::Divisions do
  def quarter_flow
    flow = HeadMusic::Content::Flow.new
    voice = flow.add_voice
    voice.place("1:1", :quarter, "C4")
    voice.place("1:2", :quarter, "D4")
    voice.place("1:3", :quarter, "E4")
    voice.place("1:4", :quarter, "F4")
    flow
  end

  def sixteenth_and_dotted_eighth_flow
    flow = HeadMusic::Content::Flow.new
    voice = flow.add_voice
    voice.place("1:1", "dotted eighth", "C4")
    voice.place("1:1:360", :sixteenth, "D4")
    voice.place("1:2", :quarter, "E4")
    voice.place("1:3", :quarter, "F4")
    voice.place("1:4", :quarter, "G4")
    flow
  end

  # flow.bars only materializes through the last bar that has a
  # placement, so the meter change is followed by a note to bring it within
  # range of the default (flow.bars) call. Position arithmetic for
  # that later note needs a real Meter (Bar#meter is a bare attr_accessor),
  # so change_meter is given a Meter instance rather than the bare string
  # the public API otherwise accepts.
  def flow_with_mid_piece_meter_change
    flow = quarter_flow
    voice = flow.voices.first
    voice.place("2:1", :quarter, "G4")
    voice.place("2:2", :quarter, "A4")
    voice.place("2:3", :quarter, "B4")
    voice.place("2:4", :quarter, "C5")
    flow.change_meter(3, HeadMusic::Rudiment::Meter.get("3/8"))
    voice.place("3:1", :eighth, "D5")
    flow
  end

  describe ".for" do
    it "returns 1 for an empty flow" do
      flow = HeadMusic::Content::Flow.new
      expect(described_class.for(flow)).to eq 1
    end

    it "returns 1 for an all-quarter-note piece in 4/4" do
      expect(described_class.for(quarter_flow)).to eq 1
    end

    it "returns 2 for a piece parsed from ABC that contains eighth notes" do
      flow = HeadMusic::Notation::ABC.parse(ABCFixtures::SPEED_THE_PLOUGH)
      expect(described_class.for(flow)).to eq 2
    end

    it "returns 4 for a piece with a sixteenth note and a dotted eighth" do
      expect(described_class.for(sixteenth_and_dotted_eighth_flow)).to eq 4
    end

    it "returns 2 for a flow whose base meter is 3/8" do
      flow = HeadMusic::Content::Flow.new(meter: "3/8")
      expect(described_class.for(flow)).to eq 2
    end

    it "picks up a mid-piece meter change from the bars" do
      expect(described_class.for(flow_with_mid_piece_meter_change)).to eq 2
    end
  end
end
