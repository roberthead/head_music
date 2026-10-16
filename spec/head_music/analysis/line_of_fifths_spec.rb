require "spec_helper"

describe HeadMusic::Analysis::LineOfFifths do
  describe ".index_of" do
    it "counts fifths from C, and seven for each sharp" do
      expect(%w[F♭ F C G B F♯ B♯ E𝄫].map { |name| described_class.index_of(name) }).to eq [-8, -1, 0, 1, 5, 6, 12, -10]
    end
  end

  describe ".spelling_at" do
    it "spells every index from F𝄫 to B𝄪" do
      expect([-15, 0, 19].map { |index| described_class.spelling_at(index).to_s }).to eq %w[F𝄫 C B𝄪]
    end

    it "is the inverse of .index_of" do
      expect(described_class::RANGE.all? { |index| described_class.index_of(described_class.spelling_at(index)) == index }).to be true
    end

    it "has nothing past a double accidental" do
      expect([described_class.spelling_at(-16), described_class.spelling_at(20)]).to eq [nil, nil]
    end
  end

  describe ".pitch_class_of" do
    it "answers the pitch class an index sounds" do
      expect([0, 6, -6, 13, 12].map { |index| described_class.pitch_class_of(index) }).to eq [0, 6, 6, 7, 0]
    end
  end

  describe ".pitch_for" do
    it "spells a double sharp" do
      expect(described_class.pitch_for(67, 13)).to eq HeadMusic::Rudiment::Pitch.get("F𝄪4")
    end

    it "spells a double flat" do
      expect(described_class.pitch_for(62, -10)).to eq HeadMusic::Rudiment::Pitch.get("E𝄫4")
    end

    it "keeps C♭ in the register above its key number's octave" do
      expect(described_class.pitch_for(59, -7).to_s).to eq "C♭4"
    end

    it "keeps B♯ in the register below its key number's octave" do
      expect(described_class.pitch_for(60, 12).to_s).to eq "B♯3"
    end

    it "refuses a triple sharp and falls back to the sharp spelling" do
      expect(described_class.pitch_at(64, 20)).to be_nil
      expect(described_class.pitch_for(64, 20).to_s).to eq "E4"
    end

    it "falls back when the spelling lies below the lowest register" do
      expect(described_class.pitch_at(0, 12)).to be_nil
      expect(described_class.pitch_for(0, 12).to_s).to eq "C-1"
    end

    it "falls back when the index does not sound the key number" do
      expect(described_class.pitch_at(61, 0)).to be_nil
      expect(described_class.pitch_for(61, 0).to_s).to eq "C♯4"
    end
  end
end
