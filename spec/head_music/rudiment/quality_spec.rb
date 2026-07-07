require "spec_helper"

describe HeadMusic::Rudiment::Quality do
  describe ".get" do
    specify { expect(described_class.get(:major)).not_to be_nil }
    specify { expect(described_class.get(:minor)).not_to be_nil }
    specify { expect(described_class.get(:diminished)).not_to be_nil }
    specify { expect(described_class.get(:augmented)).not_to be_nil }
    specify { expect(described_class.get(:salad)).to be_nil }

    context "when given an instance" do
      let(:instance) { described_class.get(:diminished) }

      it "returns that instance" do
        expect(described_class.get(instance)).to be instance
      end
    end
  end

  describe ".from" do
    specify { expect(described_class.from(:perfect, 0)).to eq "perfect" }
    specify { expect(described_class.from(:perfect, -1)).to eq "diminished" }
    specify { expect(described_class.from(:major, 0)).to eq "major" }
    specify { expect(described_class.from(:major, -1)).to eq "minor" }

    context "when the starting quality is neither perfect nor major" do
      it "returns nil" do
        expect(described_class.from(:minor, 0)).to be_nil
      end
    end
  end

  describe "equality" do
    specify { expect(described_class.get(:major)).to eq :major }
  end

  describe "predicate_methods" do
    specify { expect(described_class.get(:major)).to be_major }
    specify { expect(described_class.get(:major)).not_to be_minor }
  end
end
