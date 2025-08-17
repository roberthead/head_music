require "spec_helper"

describe HeadMusic::Rudiment::Rest do
  describe ".get" do
    context "with a rhythmic value symbol" do
      subject(:rest) { described_class.get(:quarter) }

      it "creates a rest with the specified rhythmic value" do
        expect(rest).to be_a(described_class)
        expect(rest.rhythmic_value).to eq(HeadMusic::Content::RhythmicValue.get(:quarter))
      end
    end

    context "with a RhythmicValue object" do
      subject(:rest) { described_class.get(rhythmic_value) }

      let(:rhythmic_value) { HeadMusic::Content::RhythmicValue.get(:half) }

      it "creates a rest with the specified rhythmic value" do
        expect(rest).to be_a(described_class)
        expect(rest.rhythmic_value).to eq(rhythmic_value)
      end
    end

    context "with a string description" do
      subject(:rest) { described_class.get("dotted eighth") }

      it "creates a rest with the parsed rhythmic value" do
        expect(rest).to be_a(described_class)
        expect(rest.unit.name).to eq("eighth")
        expect(rest.dots).to eq(1)
      end
    end

    context "when given an existing Rest" do
      subject(:rest) { described_class.get(original_rest) }

      let(:original_rest) { described_class.get(:whole) }

      it "returns the same rest" do
        expect(rest).to be(original_rest)
      end
    end
  end

  describe "#name" do
    subject(:rest) { described_class.get(:quarter) }

    it "returns a string representation" do
      expect(rest.name).to eq("quarter rest")
    end
  end

  describe "#to_s" do
    subject(:rest) { described_class.get(:half) }

    it "returns the name" do
      expect(rest.to_s).to eq("half rest")
    end
  end

  describe "#==" do
    let(:quarter_rest) { described_class.get(:quarter) }
    let(:another_quarter_rest) { described_class.get(:quarter) }
    let(:half_rest) { described_class.get(:half) }

    it "returns true for rests with the same rhythmic value" do
      expect(quarter_rest).to eq(another_quarter_rest)
    end

    it "returns false for rests with different rhythmic values" do
      expect(quarter_rest).not_to eq(half_rest)
    end

    it "returns false when comparing with a non-rest" do
      expect(quarter_rest).not_to eq("quarter rest")
    end
  end

  describe "#with_rhythmic_value" do
    let(:quarter_rest) { described_class.get(:quarter) }
    let(:new_rest) { quarter_rest.with_rhythmic_value(:half) }

    it "creates a new rest with the specified rhythmic value" do
      expect(new_rest).to be_a(described_class)
      expect(new_rest.rhythmic_value).to eq(HeadMusic::Content::RhythmicValue.get(:half))
      expect(new_rest).not_to eq(quarter_rest)
    end
  end

  describe "inheritance" do
    it "inherits from RhythmicElement" do
      expect(described_class.ancestors).to include(HeadMusic::Rudiment::RhythmicElement)
    end
  end

  describe "delegation" do
    subject(:rest) { described_class.get("dotted quarter") }

    it "delegates rhythmic value methods" do
      expect(rest.unit.name).to eq("quarter")
      expect(rest.dots).to eq(1)
      expect(rest.ticks).to be > 0
    end
  end

  describe "#sounded?" do
    subject(:rest) { described_class.get(:quarter) }

    it "returns false for rests" do
      expect(rest.sounded?).to be false
    end
  end
end
