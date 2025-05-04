require "spec_helper"

describe HeadMusic::Rudiment::ChromaticInterval do
  describe ".get" do
    context "when given a name" do
      it "returns the matching instance" do
        expect(described_class.get("Minor third")).to eq 3
      end
    end

    context "when given an integer" do
      it "returns the matching instance" do
        expect(described_class.get(7)).to eq described_class.get(:perfect_fifth)
      end
    end

    context "when given an instance" do
      let(:instance) { described_class.get(7) }

      it "returns that instance" do
        expect(described_class.get(instance)).to be instance
      end
    end
  end

  describe ".get_by_name" do
    context "when given a name" do
      subject(:interval) { described_class.get_by_name("perfect_fourth") }

      it "returns the matching instance" do
        expect(interval).to eq described_class.get(5)
      end

      its(:name) { is_expected.to eq "perfect_fourth" }
    end

    context "when given nonsense" do
      it "returns the default interval (perfect unison)" do
        expect(described_class.get_by_name("nonsense")).to eq described_class.get(0)
      end
    end
  end

  context "given a simple interval as an integer" do
    subject(:interval) { described_class.get(2) }

    it { is_expected.to eq 2 }
    it { is_expected.to be_simple }
    it { is_expected.to eq interval.simple }
    it { is_expected.not_to be_compound }

    its(:specific_interval) { is_expected.to eq 2 }

    context "when the integer is 0" do
      subject(:interval) { described_class.get(0) }

      it { is_expected.to be_simple }
      it { is_expected.to eq 0 }
      it { is_expected.not_to be_compound }
    end
  end

  context "given some intervals" do # rubocop:disable RSpec/MultipleMemoizedHelpers
    let(:perfect_unison) { described_class.get(:perfect_unison) }
    let(:major_third) { described_class.get(:major_third) }
    let(:minor_third) { described_class.get(:minor_third) }
    let(:perfect_fourth) { described_class.get(:perfect_fourth) }
    let(:perfect_fifth) { described_class.get(:perfect_fifth) }
    let(:perfect_octave) { described_class.get(:perfect_octave) }
    let(:perfect_11th) { described_class.get(17) }

    specify { expect(major_third).to be > minor_third }

    specify { expect(major_third + minor_third).to eq perfect_fifth }

    specify { expect(perfect_fifth - minor_third).to eq major_third }

    specify { expect(perfect_unison).to be_simple }
    specify { expect(major_third).to be_simple }
    specify { expect(perfect_octave).to be_simple }
    specify { expect(perfect_11th).not_to be_simple }

    specify { expect(perfect_unison).not_to be_compound }
    specify { expect(major_third).not_to be_compound }
    specify { expect(perfect_octave).not_to be_compound }
    specify { expect(perfect_11th).to be_compound }

    specify { expect(perfect_11th.simple).to eq(perfect_fourth) }

    specify { expect(major_third.diatonic_name).to eq "major third" }
  end
end
