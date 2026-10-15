require "spec_helper"

describe HeadMusic::Rudiment::TupletRatio do
  describe ".get" do
    it "reads actual to normal" do
      expect(described_class.get("5:4").to_a).to eq [5, 4]
    end

    it "reads a pair of numbers" do
      expect(described_class.get([7, 4]).to_a).to eq [7, 4]
    end

    it "reads 'triplet' as 3:2" do
      expect(described_class.get("triplet")).to eq described_class.get("3:2")
    end

    it "passes a ratio through" do
      ratio = described_class.get("3:2")
      expect(described_class.get(ratio)).to equal ratio
    end

    it "memoizes each ratio" do
      expect(described_class.get("6:4")).to equal described_class.get([6, 4])
    end

    it "is nil for anything that does not name a ratio" do
      expect(["quintuplet", "3/2", "", nil, 3, [3], [3, 2.0]].map { |identifier| described_class.get(identifier) })
        .to all(be_nil)
    end

    it "raises for a ratio that names no tuplet" do
      expect { described_class.get("1:1") }.to raise_error(ArgumentError, "1:1 is not a tuplet ratio")
    end

    it "raises for a non-positive number" do
      expect { described_class.get([0, 2]) }.to raise_error(ArgumentError, /0:2/)
    end
  end

  it "keeps the ratio unreduced" do
    expect(described_class.get("6:4")).not_to eq described_class.get("3:2")
  end

  describe "#factor" do
    it "is normal over actual, exactly" do
      expect(described_class.get("7:4").factor).to eq Rational(4, 7)
    end
  end

  describe "#name" do
    it "names 3:2 a triplet" do
      expect(described_class.get("3:2").name).to eq "triplet"
    end

    it "names every other ratio by its numbers" do
      expect(%w[5:4 6:4 2:3 7:4].map { |ratio| described_class.get(ratio).name }).to eq %w[5:4 6:4 2:3 7:4]
    end
  end

  describe "value equality" do
    it "counts equal ratios together" do
      ratios = [described_class.get("3:2"), described_class.get("triplet"), described_class.get("5:4")]
      expect(ratios.tally.values).to eq [2, 1]
    end
  end

  it "is frozen" do
    expect(described_class.get("3:2")).to be_frozen
  end
end
