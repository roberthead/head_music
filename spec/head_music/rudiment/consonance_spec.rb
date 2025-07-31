require "spec_helper"

describe HeadMusic::Rudiment::Consonance do
  describe "predicate_methods" do
    context "with detailed categories" do
      describe "perfect_consonance" do
        let(:consonance) { described_class.get(described_class::PERFECT_CONSONANCE) }

        specify { expect(consonance).to be_perfect_consonance }
        specify { expect(consonance).to be_consonant }
        specify { expect(consonance).not_to be_dissonant }
      end

      describe "imperfect_consonance" do
        let(:consonance) { described_class.get(described_class::IMPERFECT_CONSONANCE) }

        specify { expect(consonance).to be_imperfect_consonance }
        specify { expect(consonance).to be_consonant }
        specify { expect(consonance).not_to be_dissonant }
      end

      describe "contextual" do
        let(:consonance) { described_class.get(described_class::CONTEXTUAL) }

        specify { expect(consonance).to be_contextual }
        specify { expect(consonance).not_to be_dissonant }
        specify { expect(consonance).not_to be_consonant }
      end

      describe "mild_dissonance" do
        let(:consonance) { described_class.get(described_class::MILD_DISSONANCE) }

        specify { expect(consonance).to be_mild_dissonance }
        specify { expect(consonance).to be_dissonant }
        specify { expect(consonance).not_to be_consonant }
      end

      describe "harsh_dissonance" do
        let(:consonance) { described_class.get(described_class::HARSH_DISSONANCE) }

        specify { expect(consonance).to be_harsh_dissonance }
        specify { expect(consonance).to be_dissonant }
        specify { expect(consonance).not_to be_consonant }
      end

      describe "dissonance" do
        let(:consonance) { described_class.get(described_class::DISSONANCE) }

        specify { expect(consonance).to be_dissonance }
        specify { expect(consonance).to be_dissonant }
        specify { expect(consonance).not_to be_consonant }
      end
    end
  end

  describe ".get" do
    context "when given a bad name" do
      let(:instance) { described_class.get("#") }

      it "returns nil" do
        expect(instance).to be_nil
      end
    end

    context "when given an instance" do
      let(:instance) { described_class.get("imperfect_consonance") }

      it "returns that instance" do
        expect(described_class.get(instance)).to be instance
      end

      specify do
        expect(described_class.get(instance)).to eq described_class.get(described_class::IMPERFECT_CONSONANCE)
      end
    end
  end
end
