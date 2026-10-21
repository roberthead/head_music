require "spec_helper"

describe HeadMusic::Notation::LilyPond::TimeSignatureWriter do
  subject(:writer) { described_class.new(HeadMusic::Notation::LilyPond::RenderPlan.new(flow)) }

  let(:flow) do
    HeadMusic::Content::Flow.new(meter: "4/4").tap do |built|
      voice = built.add_voice
      [[1, :whole], [2, :whole], [3, :"dotted half"], [4, :whole], [5, :whole], [6, :whole]].each { |bar, value| voice.place("#{bar}:1", value, "C4") }
      built.change_meter(2, HeadMusic::Rudiment::Meter.common_time)
      built.change_meter(3, "3/4")
      built.change_meter(4, "2/2")
      built.change_meter(5, "4/4")
      built.change_meter(6, HeadMusic::Rudiment::Meter.cut_time)
    end
  end

  describe "#command" do
    it "asks for numerals before a 4/4 or 2/2 with no symbol, keeps them until a symbol returns, and leaves other meters bare" do
      expect((1..6).map { |bar_number| writer.command(bar_number) }).to eq [
        "\\numericTimeSignature \\time 4/4", "\\defaultTimeSignature \\time 4/4", "\\time 3/4",
        "\\numericTimeSignature \\time 2/2", "\\time 4/4", "\\defaultTimeSignature \\time 2/2"
      ]
    end

    it "has nothing to say at a bar the meter does not change at" do
      flow.add_voice.place("7:1", :whole, "C4")
      expect(writer.command(7)).to be_nil
    end

    it "writes a symbol meter with no style command" do
      common = HeadMusic::Content::Flow.new(meter: HeadMusic::Rudiment::Meter.common_time).tap { |built| built.add_voice.place("1:1", :whole, "C4") }
      expect(described_class.new(HeadMusic::Notation::LilyPond::RenderPlan.new(common)).command(1)).to eq "\\time 4/4"
    end
  end

  describe "#style" do
    it "is the style change at a later bar, alone" do
      expect((2..6).map { |bar_number| writer.style(bar_number) }).to eq ["\\defaultTimeSignature", nil, "\\numericTimeSignature", nil, "\\defaultTimeSignature"]
    end

    it "leaves the opening style to the opening command" do
      expect(writer.style(1)).to be_nil
    end
  end
end
