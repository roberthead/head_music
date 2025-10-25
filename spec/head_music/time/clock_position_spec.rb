require "spec_helper"

describe HeadMusic::Time::ClockPosition do
  describe "#initialize" do
    subject(:position) { described_class.new(nanoseconds) }

    context "with zero nanoseconds" do
      let(:nanoseconds) { 0 }

      its(:nanoseconds) { is_expected.to eq 0 }
      its(:to_i) { is_expected.to eq 0 }
      its(:to_microseconds) { is_expected.to eq 0.0 }
      its(:to_milliseconds) { is_expected.to eq 0.0 }
      its(:to_seconds) { is_expected.to eq 0.0 }
    end

    context "with one second in nanoseconds" do
      let(:nanoseconds) { 1_000_000_000 }

      its(:nanoseconds) { is_expected.to eq 1_000_000_000 }
      its(:to_i) { is_expected.to eq 1_000_000_000 }
      its(:to_microseconds) { is_expected.to eq 1_000_000.0 }
      its(:to_milliseconds) { is_expected.to eq 1_000.0 }
      its(:to_seconds) { is_expected.to eq 1.0 }
    end

    context "with 500 milliseconds in nanoseconds" do
      let(:nanoseconds) { 500_000_000 }

      its(:nanoseconds) { is_expected.to eq 500_000_000 }
      its(:to_microseconds) { is_expected.to eq 500_000.0 }
      its(:to_milliseconds) { is_expected.to eq 500.0 }
      its(:to_seconds) { is_expected.to eq 0.5 }
    end

    context "with fractional conversions" do
      let(:nanoseconds) { 1_234_567_890 }

      its(:to_microseconds) { is_expected.to eq 1_234_567.89 }
      its(:to_milliseconds) { is_expected.to eq 1_234.56789 }
      its(:to_seconds) { is_expected.to eq 1.23456789 }
    end
  end

  describe "#+" do
    subject(:result) { position1 + position2 }

    let(:position1) { described_class.new(1_000_000_000) }
    let(:position2) { described_class.new(500_000_000) }

    it "returns a ClockPosition" do
      expect(result).to be_a(described_class)
    end

    it "adds the nanoseconds together" do
      expect(result.nanoseconds).to eq 1_500_000_000
    end
  end

  describe "#<=>" do
    let(:position1) { described_class.new(1_000_000_000) }
    let(:position2) { described_class.new(2_000_000_000) }
    let(:position3) { described_class.new(1_000_000_000) }

    it "compares positions correctly" do
      expect(position1 <=> position2).to eq(-1)
      expect(position2 <=> position1).to eq(1)
      expect(position1 <=> position3).to eq(0)
    end

    it "supports comparison operators" do
      expect(position1).to be < position2
      expect(position2).to be > position1
      expect(position1).to be <= position3
      expect(position1).to be >= position3
      expect(position1).to eq position3
    end
  end

  describe "Comparable" do
    let(:position1) { described_class.new(1_000_000_000) }
    let(:position2) { described_class.new(2_000_000_000) }
    let(:position3) { described_class.new(1_500_000_000) }

    it "supports between?" do
      expect(position3).to be_between(position1, position2)
      expect(position1).not_to be_between(position2, position3)
    end
  end
end
