require "spec_helper"

describe HeadMusic::Content::Syllable do
  describe "#initialize" do
    it "coerces text to a string" do
      expect(described_class.new(:la).text).to eq "la"
    end

    it "defaults to verse 1 with no hyphen" do
      syllable = described_class.new("la")
      expect(syllable.verse).to eq 1
      expect(syllable.hyphen_after?).to be false
    end

    it "coerces verse to an integer" do
      expect(described_class.new("la", verse: "2").verse).to eq 2
    end

    it "coerces hyphen_after to a boolean" do
      expect(described_class.new("sing", hyphen_after: "yes").hyphen_after?).to be true
    end

    it "is frozen" do
      expect(described_class.new("la")).to be_frozen
    end
  end

  describe "#to_h" do
    it "includes only text for a default single-verse syllable" do
      expect(described_class.new("la").to_h).to eq("text" => "la")
    end

    it "includes verse when not the first" do
      expect(described_class.new("la", verse: 2).to_h).to eq("text" => "la", "verse" => 2)
    end

    it "includes hyphen_after when true" do
      expect(described_class.new("sing", hyphen_after: true).to_h).to eq("text" => "sing", "hyphen_after" => true)
    end
  end

  describe ".from_h" do
    it "round-trips a full hash" do
      syllable = described_class.new("sing", verse: 3, hyphen_after: true)
      expect(described_class.from_h(syllable.to_h)).to eq syllable
    end

    it "defaults the omitted keys" do
      syllable = described_class.from_h("text" => "la")
      expect(syllable.verse).to eq 1
      expect(syllable.hyphen_after?).to be false
    end
  end

  describe "#==" do
    it "is equal when the serialized shape matches" do
      one = described_class.new("la")
      two = described_class.new(:la)
      expect(one).to eq two
    end

    it "differs on hyphenation" do
      expect(described_class.new("la")).not_to eq described_class.new("la", hyphen_after: true)
    end

    it "is not equal to a non-syllable" do
      expect(described_class.new("la")).not_to eq "la"
    end
  end
end
