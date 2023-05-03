# frozen_string_literal: true

require "spec_helper"

describe HeadMusic::Quality do
  describe ".get" do
    specify { expect(described_class.get(:major)).to be }
    specify { expect(described_class.get(:minor)).to be }
    specify { expect(described_class.get(:diminished)).to be }
    specify { expect(described_class.get(:augmented)).to be }
    specify { expect(described_class.get(:salad)).to be_nil }

    context "when given an instance" do
      let(:instance) { described_class.get(:diminished) }

      it "returns that instance" do
        expect(described_class.get(instance)).to be instance
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
