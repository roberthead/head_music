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
        guide_item: HeadMusic::Style::GuideItem.new(HeadMusic::Style::Guidelines::MinimumNotes, {minimum: 1}),
        tier: :gate,
        marks: [],
        fitness: 0.4,
        violation_key: "guidelines.minimum_notes.violations.default"
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

    def graded(tier, fitness, strength = :strong)
      HeadMusic::Style::GuideItemAssessment.new(
        voice: voice, guide_item: item, tier: tier, marks: [], fitness: fitness, strength: strength
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

  # A rubric of one tier is divided by the weights it actually has, not by an
  # assumed total of 1, so a lone tier takes the full range rather than capping
  # at its budget. Both tiers are covered because a primary-only rubric divided
  # by 1.0 is wrong by phi^-1 and a secondary-only one by phi^-2, and only the
  # second is far enough off to be obvious.
  #
  # The score is asserted, never the weight sum: the equal-weights collapse
  # means a uniform tier's actual sum is its item count, not its budget.
  describe "single-tier renormalization" do
    subject(:analysis) { described_class.new(GradedStubGuide.new(assessments), voice) }

    let(:item) { HeadMusic::Style::GuideItem.new(HeadMusic::Style::Guidelines::ConsonantClimax) }

    def graded(tier, fitness)
      HeadMusic::Style::GuideItemAssessment.new(
        voice: voice, guide_item: item, tier: tier, marks: [], fitness: fitness
      )
    end

    context "with primaries alone" do
      let(:assessments) { [graded(:primary, 0.0), graded(:primary, 1.0), graded(:primary, 0.8)] }

      # Dividing by 1.0 instead would give 0.618 * 0.6 = 0.371.
      it "grades their mean rather than phi^-1 of it" do
        expect(analysis.fitness).to be_within(1e-12).of(0.6)
      end
    end

    context "with secondaries alone" do
      let(:assessments) { [graded(:secondary, 0.0), graded(:secondary, 0.5), graded(:secondary, 0.5)] }

      # Dividing by 1.0 instead would give 0.382 * 0.3333 = 0.127.
      it "grades their mean rather than phi^-2 of it" do
        expect(analysis.fitness).to be_within(1e-12).of(1.0 / 3)
      end
    end
  end

  # Strength is the rubric's second axis: within a tier, a prohibition weighs
  # twice a preference.
  describe "strength weighting" do
    subject(:analysis) { described_class.new(GradedStubGuide.new(assessments), voice) }

    let(:item) { HeadMusic::Style::GuideItem.new(HeadMusic::Style::Guidelines::ConsonantClimax) }

    def graded(fitness, strength)
      HeadMusic::Style::GuideItemAssessment.new(
        voice: voice, guide_item: item, tier: :primary, marks: [], fitness: fitness, strength: strength
      )
    end

    # Asserted as a ratio rather than as two fixture grades, and on a
    # mixed-strength tier -- a uniform one collapses to equal weights and would
    # pass this vacuously by handing back 1.0 twice.
    it "costs exactly twice as much to fail the prohibition as the preference" do
      strong_fails = described_class.new(GradedStubGuide.new([graded(0.0, :strong), graded(1.0, :weak)]), voice)
      weak_fails = described_class.new(GradedStubGuide.new([graded(1.0, :strong), graded(0.0, :weak)]), voice)

      expect(1 - strong_fails.fitness).to be_within(1e-12).of(2 * (1 - weak_fails.fitness))
    end

    it "splits a two-item tier two thirds to one" do
      strong_fails = described_class.new(GradedStubGuide.new([graded(0.0, :strong), graded(1.0, :weak)]), voice)

      expect(strong_fails.fitness).to be_within(1e-12).of(1.0 / 3)
    end

    # The equal-weights collapse survives: a uniform-strength tier gives every
    # item budget * 2 / 2n, still all equal, so the exact-mean examples above
    # stay exact and an all-strong rubric grades bit-identically to a rubric
    # with no strength axis at all.
    it "is inert until a tier mixes strengths" do
      uniform = [graded(0.5, :strong), graded(1.0, :strong), graded(0.8, :strong)]
      all_weak = [graded(0.5, :weak), graded(1.0, :weak), graded(0.8, :weak)]

      expect(described_class.new(GradedStubGuide.new(uniform), voice).fitness).to eq((0.5 + 1.0 + 0.8) / 3)
      expect(described_class.new(GradedStubGuide.new(all_weak), voice).fitness).to eq((0.5 + 1.0 + 0.8) / 3)
    end

    def graded_secondary(fitness, strength)
      HeadMusic::Style::GuideItemAssessment.new(
        voice: voice, guide_item: item, tier: :secondary, marks: [], fitness: fitness, strength: strength
      )
    end

    # Strength never crosses a tier boundary: a strong secondary still weighs
    # less than a weak primary, so the weak primary alone takes phi^-1.
    it "stays inside its tier" do
      mixed = [graded(1.0, :weak), graded_secondary(0.0, :strong)]

      expect(described_class.new(GradedStubGuide.new(mixed), voice).fitness)
        .to be_within(1e-12).of(HeadMusic::GOLDEN_RATIO_INVERSE)
    end
  end

  describe "the composite protocol" do
    let(:voice) { HeadMusic::Content::Voice.new }

    context "with a guide class" do
      let(:guide) { HeadMusic::Style::Guides::FuxCantusFirmus }

      it_behaves_like "a style assessment", assessable: false
    end

    context "with a configured guide" do
      let(:guide) { HeadMusic::Style::Guide.get!("arch_contour_melody") }

      it_behaves_like "a style assessment", assessable: false
    end

    # The leaf half of the pattern: a consumer walks assessments without asking
    # whether it holds one guide's grade or several.
    it "answers assessments with itself alone" do
      assessment = described_class.new(HeadMusic::Style::Guides::FuxCantusFirmus, voice)

      expect(assessment.assessments).to eq [assessment]
    end

    it "answers fitness_by_category as one group of one" do
      assessment = HeadMusic::Style::Guides::FirstSpeciesHarmony.assess(voice)

      expect(assessment.fitness_by_category).to eq({harmony: assessment.fitness})
    end

    # Public now, because a composite grades on its members' gate factors when
    # one of them is unassessable.
    it "reports its gate factor as a Float, even with no gates to multiply" do
      assessment = described_class.new(HeadMusic::Style::Guides::PermissiveGuide, voice)

      expect(assessment.gate_factor).to be_a(Float).and eq(1.0)
    end

    # Not a nicety: flattening a composite's items into one rubric would put
    # nineteen primaries in a single tier budget and grade by the wrong
    # arithmetic, at a number plausible enough that nobody would look.
    it "refuses a composite guide, naming the seam that grades it correctly" do
      composite = HeadMusic::Style::Guide.get!("first_species")

      expect { described_class.new(composite, voice) }
        .to raise_error(ArgumentError, /grades its members separately -- use guide\.assess/)
    end

    # Order matters: the duck-type check runs first, so a guide that is no guide
    # at all still fails as the missing duck type rather than as a missing
    # predicate.
    it "still refuses a non-guide as a non-guide" do
      expect { described_class.new(nil, voice) }
        .to raise_error(ArgumentError, /must respond to #assess_items/)
    end
  end
end
