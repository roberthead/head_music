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

  describe "#name" do
    its(:name) { is_expected.to eq "HeadMusic::Style::Guidelines::MinimumNotes" }
    its(:to_s) { is_expected.to eq assessment.name }
  end
end
