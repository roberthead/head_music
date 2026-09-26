require "spec_helper"

describe HeadMusic::Rudiment::Articulation do
  describe ".all" do
    it "lists the articulations in catalog order" do
      expect(described_class.all.map(&:name_key)).to eq %w[staccato staccatissimo accent tenuto marcato]
    end
  end

  describe ".get" do
    it "finds an articulation from a symbol" do
      expect(described_class.get(:staccato).name_key).to eq "staccato"
    end

    it "finds an articulation from a string in any case" do
      expect(described_class.get("Tenuto")).to be described_class.get(:tenuto)
    end

    it "returns the same instance each time" do
      expect(described_class.get(:accent)).to be described_class.get("accent")
    end
  end

  describe "#name" do
    it "is translated" do
      expect(described_class.get(:accent).name(locale_code: :de)).to eq "Akzent"
    end

    it "is the name in English by default" do
      expect(described_class.get(:marcato).to_s).to eq "marcato"
    end
  end

  describe "#inspect" do
    it "shows the key" do
      expect(described_class.get(:staccato).inspect).to eq "#<HeadMusic::Rudiment::Articulation staccato>"
    end
  end
end
