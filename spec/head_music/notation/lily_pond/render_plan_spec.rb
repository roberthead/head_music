require "spec_helper"

describe HeadMusic::Notation::LilyPond::RenderPlan do
  def build_flow(key_signature: "C major", meter: "4/4")
    HeadMusic::Content::Flow.new(name: "Plan", key_signature: key_signature, meter: meter)
  end

  # A placement's tokens in each bar it sounds in, joined as bar checks.
  def tokens_for(flow, placement)
    described_class.new(flow).tokens_by_segment
      .select { |segment, _| segment.placement.equal?(placement) }.values.join(" | ")
  end

  describe "#tokens_by_segment" do
    it "renders a pitched note as pitch plus duration" do
      flow = build_flow
      placement = flow.add_voice.place("1:1", :quarter, "G4")
      expect(tokens_for(flow, placement)).to eq "g'4"
    end

    it "renders a rest with its duration" do
      flow = build_flow
      placement = flow.add_voice.place("1:1", :half)
      expect(tokens_for(flow, placement)).to eq "r2"
    end

    it "joins the links of a tied chain with tie marks" do
      flow = build_flow
      value = HeadMusic::Rudiment::RhythmicValue.get("half tied to eighth")
      placement = flow.add_voice.place("1:1", value, "C4")
      expect(tokens_for(flow, placement)).to eq "c'2~ c'8"
    end

    it "renders a tied chain of rests as consecutive untied rests" do
      flow = build_flow
      value = HeadMusic::Rudiment::RhythmicValue.get("half tied to eighth")
      placement = flow.add_voice.place("1:1", value)
      expect(tokens_for(flow, placement)).to eq "r2 r8"
    end

    it "renders simultaneous pitches as a chord, low to high" do
      flow = build_flow
      placement = flow.add_voice.place("1:1", :quarter, %w[G4 C4 E4])
      expect(tokens_for(flow, placement)).to eq "<c' e' g'>4"
    end

    it "ties the whole chord across a tied chain" do
      flow = build_flow
      value = HeadMusic::Rudiment::RhythmicValue.get("half tied to eighth")
      placement = flow.add_voice.place("1:1", value, %w[C4 E4])
      expect(tokens_for(flow, placement)).to eq "<c' e'>2~ <c' e'>8"
    end

    it "ends the piece before a barline with a tie mark" do
      flow = build_flow
      flow.add_voice.place("1:1", :dotted_half, "C4")
      placement = flow.voices.first.place("1:4", :half, "D4")
      expect(tokens_for(flow, placement)).to eq "d'4~ | d'4"
    end

    it "splits a tied chain at the barline between different durations" do
      flow = build_flow
      flow.add_voice.place("1:1", :half, "C4")
      placement = flow.voices.first.place("1:3", "whole tied to quarter", "D4")
      expect(tokens_for(flow, placement)).to eq "d'2~ | d'2."
    end

    it "ties each piece of a chord across the barline" do
      flow = build_flow
      flow.add_voice.place("1:1", :dotted_half, "C4")
      placement = flow.voices.first.place("1:4", :half, %w[E4 G4])
      expect(tokens_for(flow, placement)).to eq "<e' g'>4~ | <e' g'>4"
    end

    it "splits a rest at the barline without a tie" do
      flow = build_flow
      flow.add_voice.place("1:1", :dotted_half, "C4")
      placement = flow.voices.first.place("1:4", :half)
      expect(tokens_for(flow, placement)).to eq "r4 | r4"
    end
  end

  describe "signature tracking" do
    let(:flow) do
      flow = build_flow(key_signature: "G major")
      voice = flow.add_voice
      voice.place("1:1", :whole, "G4")
      voice.place("2:1", :whole, "A4")
      voice.place("3:1", "dotted half", "D4")
      flow.change_key_signature(3, "D major")
      flow.change_meter(3, "3/4")
      HeadMusic::Notation::LilyPond::Preflight.check!(flow)
      flow
    end
    let(:plan) { described_class.new(flow) }

    it "tokenizes the first measure key" do
      expect(plan.first_measure_key).to eq "\\key g \\major"
    end

    it "records the key change token at its bar" do
      expect(plan.measure_key_changes).to eq(3 => "\\key d \\major")
    end

    it "records the meter change at its bar" do
      expect(plan.measure_time_changes.keys).to eq [3]
    end

    it "reports the effective meter after the change" do
      expect(plan.effective_meter(3).to_s).to eq "3/4"
    end

    it "reports the flow meter before the change" do
      expect(plan.effective_meter(2).to_s).to eq "4/4"
    end
  end

  describe "eager validation" do
    it "raises at construction for an unmappable key signature" do
      flow = build_flow(key_signature: "C harmonic_minor")
      flow.add_voice.place("1:1", :whole, "C4")
      expect { described_class.new(flow) }
        .to raise_error(HeadMusic::Notation::LilyPond::RenderError, /scale type/i)
    end
  end
end
