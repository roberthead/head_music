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
    subject(:result) { one_second + half_second }

    let(:one_second) { described_class.new(1_000_000_000) }
    let(:half_second) { described_class.new(500_000_000) }

    it "returns a ClockPosition" do
      expect(result).to be_a(described_class)
    end

    it "adds the nanoseconds together" do
      expect(result.nanoseconds).to eq 1_500_000_000
    end
  end

  describe "#<=>" do
    let(:one_second) { described_class.new(1_000_000_000) }
    let(:two_seconds) { described_class.new(2_000_000_000) }
    let(:also_one_second) { described_class.new(1_000_000_000) }

    it "compares positions correctly" do
      expect(one_second <=> two_seconds).to eq(-1)
      expect(two_seconds <=> one_second).to eq(1)
      expect(one_second <=> also_one_second).to eq(0)
    end

    it "supports comparison operators" do
      expect(one_second).to be < two_seconds
      expect(two_seconds).to be > one_second
      expect(one_second).to be <= also_one_second
      expect(one_second).to be >= also_one_second
      expect(one_second).to eq also_one_second
    end
  end

  describe "Comparable" do
    let(:one_second) { described_class.new(1_000_000_000) }
    let(:two_seconds) { described_class.new(2_000_000_000) }
    let(:one_and_half_seconds) { described_class.new(1_500_000_000) }

    it "supports between?" do
      expect(one_and_half_seconds).to be_between(one_second, two_seconds)
      expect(one_second).not_to be_between(two_seconds, one_and_half_seconds)
    end
  end
end
