require "spec_helper"

describe HeadMusic::Notation::ABC::TupletMarker do
  describe ".default_normal" do
    {2 => 3, 3 => 2, 4 => 3, 6 => 2, 8 => 3}.each do |actual, normal|
      it "answers #{normal} for #{actual} in any meter" do
        expect([false, true].map { |compound| described_class.default_normal(actual, compound: compound) }).to eq [normal, normal]
      end
    end

    [5, 7, 9].each do |actual|
      it "answers 2 for #{actual} in a simple meter and 3 in a compound one" do
        expect([false, true].map { |compound| described_class.default_normal(actual, compound: compound) }).to eq [2, 3]
      end
    end

    it "answers nil outside the table" do
      expect(described_class.default_normal(10, compound: false)).to be_nil
    end
  end

  describe ".for" do
    it "fills in q from the table and r from p" do
      expect(described_class.for([3, nil, nil], compound: false).to_h).to eq(actual: 3, normal: 2, count: 3)
    end

    it "keeps a given q and r" do
      expect(described_class.for([5, 4, 3], compound: false).to_h).to eq(actual: 5, normal: 4, count: 3)
    end

    it "takes the table's q when only r is given" do
      expect(described_class.for([3, nil, 2], compound: true).to_h).to eq(actual: 3, normal: 2, count: 2)
    end

    it "raises when p is outside the table and q is missing" do
      expect { described_class.for([11, nil, nil], compound: false, line: 4) }
        .to raise_error(HeadMusic::Notation::ABC::ParseError, /needs a q.*line 4/)
    end

    it "raises for a zero" do
      expect { described_class.for([3, 2, 0], compound: false) }
        .to raise_error(HeadMusic::Notation::ABC::ParseError, /positive/) { |error| expect(error.snippet).to eq "(3:2:0" }
    end
  end

  describe "#ratio" do
    it "answers the tuplet ratio, unreduced" do
      expect(described_class.for([6, 4, nil], compound: false).ratio).to eq HeadMusic::Rudiment::TupletRatio.get("6:4")
    end

    it "answers nil for a marker that changes no length" do
      expect(described_class.for([3, 3, nil], compound: false).ratio).to be_nil
    end
  end
end
