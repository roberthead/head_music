require "spec_helper"

class HeadMusic::Style::Guides::PermissiveGuide
  def self.assess_items(voice)
    []
  end
end

# A guide is a duck type -- a guide class, a Guides::Configured, or this --
# so there is no class for a verifying double to check against. Stubbing it
# explicitly says which method the contract actually rests on.
class GradedStubGuide
  def initialize(assessments)
    @assessments = assessments
  end

  def assess_items(_voice)
    @assessments
  end
end

describe HeadMusic::Style::GuideAssessment do
  subject(:analysis) { described_class.new(guide, voice) }

  let(:voice) { HeadMusic::Content::Voice.new }

  context "with the Fux Cantus Firmus guide" do
    let(:guide) { HeadMusic::Style::Guides::FuxCantusFirmus }

    its(:guide) { is_expected.to eq HeadMusic::Style::Guides::FuxCantusFirmus }
    its(:voice) { is_expected.to be voice }
    its(:guide_item_assessments) { are_expected.to be_an(Array) }
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
        expect(analysis.guide_item_assessments).to all(be_adherent)
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
        expect(analysis.guide_item_assessments.any? { |assessment| !assessment.adherent? }).to be true
        expect(analysis).not_to be_adherent
      end
    end
  end

  context "when every guideline is a gate" do
    let(:guide) { double("Guide", assess_items: [gate_item_assessment]) } # rubocop:disable RSpec/VerifiedDoubles
    let(:gate_item_assessment) do
      HeadMusic::Style::GuideItemAssessment.new(
        voice: voice,
        guide_item: HeadMusic::Style::GuideItem.new(HeadMusic::Style::Guidelines::MinimumNotes, minimum: 1),
        tier: :gate,
        marks: [],
        fitness: 0.4,
        message: "gated"
      )
    end

    it "grades by the gate factor alone (rubric fitness defaults to 1.0)" do
      expect(analysis.fitness).to be_within(0.0001).of(0.4)
    end
  end

  describe "guide validation" do
    # A key that misses in the registry yields nil, and without this guard that
    # nil travels to #guide_item_assessments before failing far from the bad key.
    it "rejects nil with an error naming the missing behavior" do
      expect { described_class.new(nil, voice) }.to raise_error(ArgumentError, /assess_items/)
    end

    it "rejects an object that cannot assess items" do
      expect { described_class.new(Object.new, voice) }.to raise_error(ArgumentError, /assess_items/)
    end

    it "accepts a guide class" do
      expect { described_class.new(HeadMusic::Style::Guides::FuxCantusFirmus, voice) }.not_to raise_error
    end

    it "accepts a configured guide" do
      guide = HeadMusic::Style::Guide.get("arch_contour_melody")
      expect { described_class.new(guide, voice) }.not_to raise_error
    end

    it "accepts any object that answers assess_items" do
      expect { described_class.new(HeadMusic::Style::Guides::PermissiveGuide, voice) }.not_to raise_error
    end
  end

  context "with a permissive guide" do
    let(:guide) { HeadMusic::Style::Guides::PermissiveGuide }

    its(:guide) { is_expected.to eq HeadMusic::Style::Guides::PermissiveGuide }
    its(:voice) { is_expected.to be voice }
    its(:guide_item_assessments) { are_expected.to be_empty }
    its(:messages) { is_expected.to be_empty }
    its(:fitness) { is_expected.to eq 1.0 }
    its(:adherent?) { is_expected.to be true }
  end

  # The arithmetic that replaced per-item weights. Only the oracle exercised
  # this end to end; these pin it directly.
  describe "tier weighting" do
    subject(:analysis) { described_class.new(guide, voice) }

    let(:guide) { GradedStubGuide.new(assessments) }
    let(:item) { HeadMusic::Style::GuideItem.new(HeadMusic::Style::Guidelines::ConsonantClimax) }

    def graded(tier, fitness)
      HeadMusic::Style::GuideItemAssessment.new(
        voice: voice, guide_item: item, tier: tier, marks: [], fitness: fitness
      )
    end

    context "when every rubric entry is a primary" do
      let(:assessments) { [graded(:primary, 0.5), graded(:primary, 1.0), graded(:primary, 0.8)] }

      # Equal weights are an unweighted mean, and are computed as one: scaling
      # each term by phi^-1/n and dividing the sum back out drifts by an ulp in
      # binary. This asserts the exact mean, not an approximation of it.
      it "grades the plain mean, exactly" do
        expect(analysis.fitness).to eq((0.5 + 1.0 + 0.8) / 3)
      end
    end

    context "when the guide teaches one thing over inherited background" do
      let(:assessments) { [graded(:primary, 1.0), graded(:secondary, 0.0), graded(:secondary, 0.0)] }

      # phi^-1 + phi^-2 = 1, so a perfect lesson against wholly failed
      # background grades the lesson's share and nothing else.
      it "gives the lesson phi^-1 of the rubric" do
        expect(analysis.fitness).to be_within(1e-12).of(
          HeadMusic::GOLDEN_RATIO_INVERSE / (HeadMusic::GOLDEN_RATIO_INVERSE + HeadMusic::GOLDEN_RATIO_INVERSE**2)
        )
      end
    end

    context "when a gate falls short" do
      let(:assessments) { [graded(:gate, 0.5), graded(:primary, 1.0)] }

      it "scales the whole grade rather than trading off against the rubric" do
        expect(analysis.fitness).to eq 0.5
      end
    end

    context "when a guide declares only secondaries" do
      let(:assessments) { [graded(:secondary, 0.4), graded(:secondary, 0.6)] }

      # Weights are normalized by their own sum, so a tier nobody declared
      # cannot divide by zero and a lone tier still grades as its own mean.
      it "grades their mean" do
        expect(analysis.fitness).to eq 0.5
      end
    end
  end
end
