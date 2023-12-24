require "spec_helper"

describe HeadMusic::Utilities::HashKey do
  describe ".for" do
    it "strips diacritics" do
      expect(described_class.for("Violinschlüssel")).to eq :violinschlussel
    end

    it "underscores" do
      expect(described_class.for("French Horn")).to eq :french_horn
    end
  end
end
