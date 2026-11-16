require "spec_helper"

describe HeadMusic::Style::Guideline::VoiceContext do
  subject(:context) { host_class.new(flow.voices.first) }

  let(:host_class) do
    Class.new do
      include HeadMusic::Style::Guideline::VoiceContext

      public :downbeat_position?, :strong_beat_position?, :bar_downbeats, :next_strong_beat, :restruck_on_stronger_beat?

      attr_reader :voice

      def initialize(voice)
        @voice = voice
      end
    end
  end

  def flow_for(meter:, upper:, lower:)
    HeadMusic::Notation::ABC.parse(<<~ABC)
      X:1
      M:#{meter}
      L:1/4
      K:Ddor
      V:upper
      #{upper}
      V:lower
      #{lower}
    ABC
  end

  def position(flow, code)
    HeadMusic::Content::Position.new(flow, code)
  end

  context "with 4/4 against a lower voice that moves within the bar" do
    let(:flow) { flow_for(meter: "4/4", upper: "a4|f4|]", lower: "D2 F2|A, B, C D|]") }

    it "finds the downbeat on beat one only, not where the other voice attacks" do
      expect(context.downbeat_position?(position(flow, "2:1:000"))).to be true
      expect(context.downbeat_position?(position(flow, "1:3:000"))).to be false
    end

    it "counts beats one and three as strong" do
      expect(%w[2:1:000 2:2:000 2:3:000 2:4:000].map { |code| context.strong_beat_position?(position(flow, code)) })
        .to eq [true, false, true, false]
    end

    it "finds the next strong beat later in the bar, or else the next downbeat" do
      expect(%w[1:1:000 1:2:000 1:3:000 1:4:000].map { |code| context.next_strong_beat(position(flow, code)).to_s })
        .to eq %w[1:3:000 1:3:000 2:1:000 2:1:000]
    end

    it "walks one downbeat per bar across the passage" do
      expect(context.bar_downbeats.map(&:to_s)).to eq %w[1:1:000 2:1:000]
    end
  end

  context "with 2/2" do
    let(:flow) { flow_for(meter: "2/2", upper: "a4|f4|]", lower: "D4|F4|]") }

    it "counts both beats strong, as beats one and three are in 4/4" do
      expect(%w[1:1:000 1:2:000].map { |code| context.strong_beat_position?(position(flow, code)) }).to eq [true, true]
    end
  end

  context "with 3/2" do
    let(:flow) { flow_for(meter: "3/2", upper: "a6|f6|]", lower: "D2 E2 F2|G6|]") }

    it "counts only beat one strong" do
      expect(%w[1:1:000 1:2:000 1:3:000].map { |code| context.strong_beat_position?(position(flow, code)) })
        .to eq [true, false, false]
    end

    it "finds the next strong beat in the next bar" do
      expect(context.next_strong_beat(position(flow, "1:1:000")).to_s).to eq "2:1:000"
    end

    it "finds the downbeat on beat one" do
      expect(context.downbeat_position?(position(flow, "1:2:000"))).to be false
      expect(context.downbeat_position?(position(flow, "2:1:000"))).to be true
    end
  end

  context "with a staggered entry" do
    let(:flow) { flow_for(meter: "4/4", upper: "z4|a4|f4|]", lower: "D4|F4|E4|]") }

    it "walks the downbeats from the first entry of either voice" do
      expect(context.bar_downbeats.map(&:to_s)).to eq %w[1:1:000 2:1:000 3:1:000]
    end
  end

  context "with no other voice" do
    let(:flow) do
      HeadMusic::Notation::ABC.parse("X:1\nM:4/4\nL:1/4\nK:Ddor\nD2 F2|A4|]\n")
    end

    it "still reads the downbeat from the meter" do
      expect(context.downbeat_position?(position(flow, "2:1:000"))).to be true
      expect(context.downbeat_position?(position(flow, "1:3:000"))).to be false
    end
  end

  describe "#restruck_on_stronger_beat?" do
    let(:flow) { flow_for(meter: "4/4", upper: "e2 f2|f2 f e|d4|]", lower: "D4|D4|D4|]") }
    let(:upper_notes) { flow.voices.first.notes }

    it "finds a pitch struck again on a stronger beat" do
      expect(context.restruck_on_stronger_beat?(upper_notes[2])).to be true
    end

    it "ignores a pitch struck again on a weaker beat" do
      expect(context.restruck_on_stronger_beat?(upper_notes[3])).to be false
    end

    it "ignores a note that moved" do
      expect(context.restruck_on_stronger_beat?(upper_notes[1])).to be false
    end

    it "ignores the first note" do
      expect(context.restruck_on_stronger_beat?(upper_notes[0])).to be false
    end
  end
end
