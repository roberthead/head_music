require "spec_helper"

describe HeadMusic::Consonance do
  describe "predicate_methods" do
    context "when perfect" do
      specify { expect(described_class.get(:perfect)).to be_perfect }
      specify { expect(described_class.get(:perfect)).not_to be_imperfect }
      specify { expect(described_class.get(:perfect)).not_to be_dissonant }
    end

    context "when imperfect" do
      specify { expect(described_class.get(:imperfect)).not_to be_perfect }
      specify { expect(described_class.get(:imperfect)).to be_imperfect }
      specify { expect(described_class.get(:imperfect)).not_to be_dissonant }
    end

    context "when dissonant" do
      specify { expect(described_class.get(:dissonant)).not_to be_perfect }
      specify { expect(described_class.get(:dissonant)).not_to be_imperfect }
      specify { expect(described_class.get(:dissonant)).to be_dissonant }
    end
  end

  describe ".get" do
    context "when given an instance" do
      let(:instance) { described_class.get("#") }

      it "returns that instance" do
        expect(described_class.get(instance)).to be instance
      end
    end
  end
end
