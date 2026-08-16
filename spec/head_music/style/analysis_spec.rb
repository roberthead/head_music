require "spec_helper"

class HeadMusic::Style::Guides::PermissiveGuide
  def self.analyze(voice)
    []
  end
end

describe HeadMusic::Style::Analysis do
  subject(:analysis) { described_class.new(guide, voice) }

  let(:voice) { HeadMusic::Content::Voice.new }

  context "with the Fux Cantus Firmus guide" do
    let(:guide) { HeadMusic::Style::Guides::FuxCantusFirmus }

    its(:guide) { is_expected.to eq HeadMusic::Style::Guides::FuxCantusFirmus }
    its(:voice) { is_expected.to be voice }
    its(:annotations) { are_expected.to be_an(Array) }
    its(:fitness) { is_expected.to be_a(Float) }

    describe "with notes" do
      before do
        voice.place("1:1", :whole, "C4")
        voice.place("2:1", :whole, "D4")
        voice.place("3:1", :whole, "E4")
        voice.place("4:1", :whole, "G4")
        voice.place("5:1", :whole, "E4")
        voice.place("6:1", :whole, "F4")
        voice.place("7:1", :whole, "D4")
        voice.place("8:1", :whole, "C4")
      end

      its(:fitness) { is_expected.to eq 1.0 }

      it "is adherent when every guideline is adherent" do
        expect(analysis.annotations).to all(be_adherent)
        expect(analysis).to be_adherent
      end
    end

    context "when not adhering to the guide" do
      before do
        voice.place("1:1", :whole, "C4")
        voice.place("2:1", :whole, "D4")
        voice.place("3:1", :whole, "G4")
        voice.place("4:1", :whole, "F4")
        voice.place("5:1", :whole, "E4")
        voice.place("6:1", :whole, "F4")
        voice.place("7:1", :whole, "B3") # dissonant leap
        voice.place("8:1", :whole, "C4")
      end

      its(:fitness) { is_expected.to be < 1.0 }

      it "is not adherent when any guideline is not adherent" do
        expect(analysis.annotations.any? { |guideline| !guideline.adherent? }).to be true
        expect(analysis).not_to be_adherent
      end
    end
  end

  context "when every guideline is a gate" do
    let(:guide) { double("Guide", analyze: [gate_guideline]) } # rubocop:disable RSpec/VerifiedDoubles
    let(:gate_guideline) do
      instance_double(HeadMusic::Style::Guideline, gate?: true, fitness: 0.4, adherent?: false, weight: 1, message: "gated")
    end

    it "grades by the gate factor alone (rubric fitness defaults to 1.0)" do
      expect(analysis.fitness).to be_within(0.0001).of(0.4)
    end
  end

  describe "guide validation" do
    # A key that misses in the registry yields nil, and without this guard that
    # nil travels to #annotations before failing far from the bad key.
    it "rejects nil with an error naming the missing behavior" do
      expect { described_class.new(nil, voice) }.to raise_error(ArgumentError, /analyze/)
    end

    it "rejects an object that cannot analyze" do
      expect { described_class.new(Object.new, voice) }.to raise_error(ArgumentError, /analyze/)
    end

    it "accepts a guide class" do
      expect { described_class.new(HeadMusic::Style::Guides::FuxCantusFirmus, voice) }.not_to raise_error
    end

    it "accepts a configured guide" do
      guide = HeadMusic::Style::Guide.get("arch_contour_melody")
      expect { described_class.new(guide, voice) }.not_to raise_error
    end

    it "accepts any object that answers analyze" do
      expect { described_class.new(HeadMusic::Style::Guides::PermissiveGuide, voice) }.not_to raise_error
    end
  end

  context "with a permissive guide" do
    let(:guide) { HeadMusic::Style::Guides::PermissiveGuide }

    its(:guide) { is_expected.to eq HeadMusic::Style::Guides::PermissiveGuide }
    its(:voice) { is_expected.to be voice }
    its(:annotations) { are_expected.to be_empty }
    its(:messages) { is_expected.to be_empty }
    its(:fitness) { is_expected.to eq 1.0 }
    its(:adherent?) { is_expected.to be true }
  end
end
