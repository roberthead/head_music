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

  # Accidental signs become word suffixes. Doubles are matched before singles: the
  # single-sharp rule would otherwise consume the first character of "##" and leave a
  # stray "#" behind.
  describe "accidental signs" do
    {
      "C♯" => :c_sharp,
      "C#" => :c_sharp,
      "C♭" => :c_flat,
      "C𝄪" => :c_double_sharp,
      "C##" => :c_double_sharp,
      "C𝄫" => :c_double_flat,
      "C♮" => :c_natural
    }.each do |identifier, expected|
      specify { expect(described_class.for(identifier)).to eq expected }
    end

    # ASCII "b" is deliberately not mapped, or every key containing the letter would
    # be mangled.
    it "leaves a word containing the letter b intact" do
      expect(described_class.for("blues_major_pentatonic")).to eq :blues_major_pentatonic
    end

    it "leaves an instrument name containing the letter b intact" do
      expect(described_class.for("bass clarinet")).to eq :bass_clarinet
    end
  end
end
