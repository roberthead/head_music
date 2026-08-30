require "spec_helper"

describe HeadMusic::Notation::LilyPond::RenderPlan do
  def build_composition(key_signature: "C major", meter: "4/4")
    HeadMusic::Content::Composition.new(name: "Plan", key_signature: key_signature, meter: meter)
  end

  describe "#tokens_by_placement" do
    it "renders a pitched note as pitch plus duration" do
      composition = build_composition
      placement = composition.add_voice.place("1:1", :quarter, "G4")
      expect(described_class.new(composition).tokens_by_placement[placement]).to eq "g'4"
    end

    it "renders a rest with its duration" do
      composition = build_composition
      placement = composition.add_voice.place("1:1", :half)
      expect(described_class.new(composition).tokens_by_placement[placement]).to eq "r2"
    end

    it "joins the links of a tied chain with tie marks" do
      composition = build_composition
      value = HeadMusic::Rudiment::RhythmicValue.get("half tied to eighth")
      placement = composition.add_voice.place("1:1", value, "C4")
      expect(described_class.new(composition).tokens_by_placement[placement]).to eq "c'2~ c'8"
    end

    it "renders a tied chain of rests as consecutive untied rests" do
      composition = build_composition
      value = HeadMusic::Rudiment::RhythmicValue.get("half tied to eighth")
      placement = composition.add_voice.place("1:1", value)
      expect(described_class.new(composition).tokens_by_placement[placement]).to eq "r2 r8"
    end

    it "renders simultaneous pitches as a chord, low to high" do
      composition = build_composition
      placement = composition.add_voice.place("1:1", :quarter, %w[G4 C4 E4])
      expect(described_class.new(composition).tokens_by_placement[placement]).to eq "<c' e' g'>4"
    end

    it "ties the whole chord across a tied chain" do
      composition = build_composition
      value = HeadMusic::Rudiment::RhythmicValue.get("half tied to eighth")
      placement = composition.add_voice.place("1:1", value, %w[C4 E4])
      expect(described_class.new(composition).tokens_by_placement[placement]).to eq "<c' e'>2~ <c' e'>8"
    end
  end

  describe "signature tracking" do
    let(:composition) do
      composition = build_composition(key_signature: "G major")
      voice = composition.add_voice
      voice.place("1:1", :whole, "G4")
      voice.place("2:1", :whole, "A4")
      voice.place("3:1", "dotted half", "D4")
      composition.change_key_signature(3, "D major")
      composition.change_meter(3, "3/4")
      HeadMusic::Notation::LilyPond::Preflight.check!(composition)
      composition
    end
    let(:plan) { described_class.new(composition) }

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

    it "reports the composition meter before the change" do
      expect(plan.effective_meter(2).to_s).to eq "4/4"
    end
  end

  describe "eager validation" do
    it "raises at construction for an unmappable key signature" do
      composition = build_composition(key_signature: "C harmonic_minor")
      composition.add_voice.place("1:1", :whole, "C4")
      expect { described_class.new(composition) }
        .to raise_error(HeadMusic::Notation::LilyPond::RenderError, /scale type/i)
    end
  end
end
