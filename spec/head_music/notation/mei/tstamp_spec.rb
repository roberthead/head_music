require "spec_helper"

describe HeadMusic::Notation::MEI::Tstamp do
  def abc(body, meter: "4/4")
    HeadMusic::Notation::ABC.parse("X:1\nT:Tstamp\nM:#{meter}\nL:1/8\nK:C\n#{body}\n")
  end

  describe ".beat" do
    it "counts beats from 1 in the meter's unit" do
      flow = abc("C2 D2 E2 F2|]")
      expect(%w[1:1 1:2 1:3:480].map { |code| described_class.beat(flow, flow.position(code)) }).to eq %w[1 2 3.5]
    end

    it "counts eighths in 6/8" do
      flow = abc("CDE FGA|]", meter: "6/8")
      expect(described_class.beat(flow, flow.position("1:5"))).to eq "5"
    end

    it "counts in a pickup bar as in any other" do
      flow = LilyPondFixtures.pickup_and_short_final_bar
      expect(described_class.beat(flow, flow.position("0:3"))).to eq "3"
    end

    it "takes the exact onset of a triplet note, to four places" do
      flow = abc("(3CDE z2 z4|]")
      second = flow.voices.first.voice_events[1]
      expect(described_class.beat(flow, second.position)).to eq "1.3333"
    end

    it "is 0 before the first beat" do
      flow = abc("C8|]")
      expect(described_class.beat(flow, flow.position(1, 0))).to eq "0"
    end
  end

  describe ".tstamp2" do
    it "counts the bars to the end and its beat there" do
      flow = abc("C8|D8|E8|]")
      expect(described_class.tstamp2(flow, flow.position("1:2"), flow.position("3:3"))).to eq "2m+3"
    end

    it "is the beat after the last in the last bar at the final barline" do
      flow = abc("C8|D6|]", meter: "4/4")
      expect(described_class.tstamp2(flow, flow.position("1:1"), flow.final_barline_position)).to eq "1m+5"
    end

    it "counts the beat in the meter of the bar it ends in" do
      flow = abc("C8|D6|]").tap { |changed| changed.change_meter(2, "6/8") }
      expect(described_class.tstamp2(flow, flow.position("1:1"), flow.position("2:4"))).to eq "1m+4"
    end
  end
end
