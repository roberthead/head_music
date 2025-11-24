require "spec_helper"

describe HeadMusic::Instruments::PlayingTechnique do
  describe ".get" do
    it "returns the identifier if it is already a PlayingTechnique" do
      technique = described_class.new("stick")
      expect(described_class.get(technique)).to be(technique)
    end

    it "creates a PlayingTechnique from a string" do
      technique = described_class.get("stick")
      expect(technique).to be_a(described_class)
      expect(technique.name_key).to eq("stick")
    end

    it "creates a PlayingTechnique from a symbol" do
      technique = described_class.get(:stick)
      expect(technique).to be_a(described_class)
      expect(technique.name_key).to eq("stick")
    end

    it "converts camelCase to snake_case" do
      technique = described_class.get("rimShot")
      expect(technique.name_key).to eq("rim_shot")
    end

    it "converts PascalCase to snake_case" do
      technique = described_class.get("RimShot")
      expect(technique.name_key).to eq("rim_shot")
    end
  end

  describe ".all" do
    it "returns an array of all techniques" do
      techniques = described_class.all
      expect(techniques).to be_an(Array)
      expect(techniques).not_to be_empty
    end

    it "returns PlayingTechnique objects" do
      techniques = described_class.all
      expect(techniques.first).to be_a(described_class)
    end

    it "includes all defined techniques" do
      techniques = described_class.all
      technique_names = techniques.map(&:name_key)
      expect(technique_names).to include("stick", "pedal", "mallet")
    end
  end

  describe "#initialize" do
    it "accepts a string name_key" do
      technique = described_class.new("stick")
      expect(technique.name_key).to eq("stick")
    end

    it "converts symbol to string" do
      technique = described_class.new(:stick)
      expect(technique.name_key).to eq("stick")
    end
  end

  describe "#name" do
    it "returns the name with underscores replaced by spaces" do
      technique = described_class.new("rim_shot")
      expect(technique.name).to eq("rim shot")
    end

    it "returns the name unchanged if no underscores" do
      technique = described_class.new("stick")
      expect(technique.name).to eq("stick")
    end
  end

  describe "#to_s" do
    it "returns the same value as #name" do
      technique = described_class.new("rim_shot")
      expect(technique.to_s).to eq(technique.name)
    end
  end

  describe "#==" do
    let(:stick) { described_class.new("stick") }
    let(:another_stick) { described_class.new("stick") }
    let(:mallet) { described_class.new("mallet") }

    it "returns true for techniques with the same name_key" do
      expect(stick).to eq(another_stick)
    end

    it "returns false for techniques with different name_keys" do
      expect(stick).not_to eq(mallet)
    end

    it "returns false when compared to a non-PlayingTechnique object" do
      expect(stick).not_to eq("stick")
    end

    it "returns false when compared to nil" do
      expect(stick).not_to be_nil
    end
  end

  describe "#eql?" do
    let(:stick) { described_class.new("stick") }
    let(:another_stick) { described_class.new("stick") }

    it "returns the same value as #==" do
      expect(stick.eql?(another_stick)).to eq(stick == another_stick)
    end
  end

  describe "#hash" do
    let(:stick) { described_class.new("stick") }
    let(:another_stick) { described_class.new("stick") }
    let(:mallet) { described_class.new("mallet") }

    it "returns the same hash for techniques with the same name_key" do
      expect(stick.hash).to eq(another_stick.hash)
    end

    it "returns different hashes for techniques with different name_keys" do
      expect(stick.hash).not_to eq(mallet.hash)
    end

    it "allows techniques to be used as hash keys" do
      hash = {stick => "value1"}
      hash[another_stick] = "value2"
      expect(hash.size).to eq(1)
      expect(hash[stick]).to eq("value2")
    end
  end

  describe "named mixin integration" do
    it "includes HeadMusic::Named" do
      expect(described_class.ancestors).to include(HeadMusic::Named)
    end
  end

  describe "common techniques" do
    it "defines TECHNIQUES constant" do
      expect(described_class::TECHNIQUES).to be_an(Array)
    end

    it "includes stick technique" do
      expect(described_class::TECHNIQUES).to include("stick")
    end

    it "includes pedal technique" do
      expect(described_class::TECHNIQUES).to include("pedal")
    end

    it "includes bow technique" do
      expect(described_class::TECHNIQUES).to include("bow")
    end
  end
end
