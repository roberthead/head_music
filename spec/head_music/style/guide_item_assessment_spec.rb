require "spec_helper"

describe HeadMusic::Style::GuideItemAssessment do
  subject(:assessment) { guide_item.assess(voice, tier) }

  let(:composition) { HeadMusic::Content::Composition.new(key_signature: "D dorian") }
  let(:voice) { HeadMusic::Content::Voice.new(composition: composition, role: "Cantus Firmus") }
  let(:guide_item) { HeadMusic::Style::Guidelines::MinimumNotes.with(minimum) }
  let(:minimum) { 5 }
  let(:tier) { :primary }

  before { %w[D4 E4 F4].each_with_index { |pitch, bar| voice.place("#{bar + 1}:1", :whole, pitch) } }

  describe "what it holds" do
    its(:voice) { is_expected.to be voice }
    its(:guide_item) { is_expected.to be guide_item }
    its(:tier) { is_expected.to eq :primary }

    it "delegates the guideline and its configuration to the item" do
      expect(assessment.guideline).to eq HeadMusic::Style::Guidelines::MinimumNotes
      expect(assessment.config).to eq(minimum: 5)
    end
  end

  # Stamped for a different reason than tier: an item does have a single
  # strength. A persisted assessment records the severity in force when it was
  # graded, so re-classifying a guideline later cannot rewrite old grades.
  describe "strength" do
    its(:strength) { is_expected.to eq :strong }

    context "when the guideline declares a preference" do
      let(:guide_item) { HeadMusic::Style::Guidelines::LimitOctaveLeaps.with }

      its(:strength) { is_expected.to eq :weak }
    end

    context "when the item overrides the guideline" do
      let(:guide_item) { HeadMusic::Style::Guidelines::MinimumNotes.with(minimum, strength: :weak) }

      its(:strength) { is_expected.to eq :weak }
    end

    # Keyword-defaulted rather than required, so the direct-construction sites
    # in specs and any external consumer keep working.
    it "can be constructed without naming one" do
      direct = described_class.new(
        voice: voice, guide_item: guide_item, tier: :primary, marks: [], fitness: 1.0
      )

      expect(direct.strength).to eq :strong
    end

    it "records what it was given rather than re-asking the item" do
      direct = described_class.new(
        voice: voice, guide_item: guide_item, tier: :primary, marks: [], fitness: 1.0, strength: :weak
      )

      expect(direct.strength).to eq :weak
    end

    # This is a seam a caller can reach without going through GuideItem, so it
    # validates too. Unvalidated, the value survives construction and surfaces
    # as a bare KeyError from Strength.units during grading, far from the
    # assessment that carried it.
    it "rejects a strength the guideline could not have declared" do
      expect {
        described_class.new(
          voice: voice, guide_item: guide_item, tier: :primary, marks: [], fitness: 1.0, strength: :medium
        )
      }.to raise_error(ArgumentError, /strength must be one of: strong, weak/)
    end
  end

  describe "immutability" do
    it { is_expected.to be_frozen }

    it "holds its marks rather than recomputing them" do
      expect(assessment.marks).to be(assessment.marks).and be_frozen
    end
  end

  describe "#fitness" do
    context "when the voice falls short" do
      it "reports the shortfall as a proportion" do
        expect(assessment.fitness).to be_within(1e-9).of(3.0 / 5)
      end

      it { is_expected.not_to be_adherent }
    end

    context "when the voice meets the minimum" do
      let(:minimum) { 3 }

      it { is_expected.to be_adherent }
      its(:fitness) { is_expected.to eq 1 }
    end
  end

  describe "#gate?" do
    context "when the item was declared as a gate" do
      let(:tier) { :gate }

      it { is_expected.to be_gate }
    end

    context "when the item was declared in a rubric tier" do
      it { is_expected.not_to be_gate }
    end

    # The same item can be a gate in one guide and a rubric entry in another,
    # which is why tier is stamped at assess time rather than read off the item.
    it "takes its tier from the assessment rather than the item" do
      expect(guide_item.assess(voice, :gate)).to be_gate
      expect(guide_item.assess(voice, :secondary)).not_to be_gate
    end
  end

  describe "positions" do
    it "spans the marks it holds" do
      expect(assessment.start_position).to eq assessment.marks.map(&:start_position).min
      expect(assessment.end_position).to eq assessment.marks.map(&:end_position).max
    end
  end

  # A consumer building a results list holds assessments, not items, so this is
  # where the rubric gets its labels. Answering with the class path meant the
  # rendered name was reachable only by going through guide_item.
  describe "#name" do
    its(:name) { is_expected.to eq "Minimum of five notes" }
    its(:to_s) { is_expected.to eq assessment.name }

    it "says what this guide configured, as the item does" do
      expect(assessment.name).to eq guide_item.name
    end
  end
end
