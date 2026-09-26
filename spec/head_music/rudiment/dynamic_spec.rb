require "spec_helper"

describe HeadMusic::Rudiment::Dynamic do
  describe ".levels" do
    it "lists the levels from softest to loudest" do
      expect(described_class.levels.map(&:name_key)).to eq %w[ppp pp p mp mf f ff fff]
    end
  end

  describe ".accents" do
    it "lists the accents" do
      expect(described_class.accents.map(&:name_key)).to eq %w[sf sfz rfz fp]
    end
  end

  describe ".get" do
    it "ignores case" do
      expect(described_class.get("MF")).to be described_class.get(:mf)
    end
  end

  describe "#level? and #accent?" do
    it "knows a level" do
      expect(described_class.get(:p)).to have_attributes(level?: true, accent?: false)
    end

    it "knows an accent" do
      expect(described_class.get(:sfz)).to have_attributes(level?: false, accent?: true)
    end
  end

  describe "#level_after" do
    it "is p after fp" do
      expect(described_class.get(:fp).level_after).to be described_class.get(:p)
    end

    it "is nil after sfz" do
      expect(described_class.get(:sfz).level_after).to be_nil
    end

    it "is nil after a level" do
      expect(described_class.get(:f).level_after).to be_nil
    end
  end

  describe "#name" do
    it "uses the Italian term" do
      expect(described_class.get(:pp).name).to eq "pianissimo"
    end

    it "is spelled in Cyrillic in Russian" do
      expect(described_class.get(:fp).name(locale_code: :ru)).to eq "фортепиано"
    end
  end
end
