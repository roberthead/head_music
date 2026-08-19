require "spec_helper"

describe HeadMusic::Rudiment::Pitch::Arithmetic do
  def pitch(name)
    HeadMusic::Rudiment::Pitch.get(name)
  end

  def interval(name)
    HeadMusic::Analysis::DiatonicInterval.get(name)
  end

  describe "#sum" do
    it "raises the pitch by a diatonic interval" do
      expect(described_class.new(pitch("C4"), interval("major third")).sum).to eq pitch("E4")
    end

    it "raises the pitch by a number of semitones" do
      expect(described_class.new(pitch("C4"), 4).sum).to eq pitch("E4")
    end

    it "carries into the next register" do
      expect(described_class.new(pitch("A4"), 3).sum).to eq pitch("C5")
    end

    it "reads another pitch as its semitone number" do
      expect(described_class.new(pitch("C4"), pitch("C-1")).sum).to eq pitch("C4")
    end
  end

  describe "#difference" do
    it "lowers the pitch by a diatonic interval" do
      expect(described_class.new(pitch("E4"), interval("major third")).difference).to eq pitch("C4")
    end

    it "lowers the pitch by a number of semitones" do
      expect(described_class.new(pitch("E4"), 4).difference).to eq pitch("C4")
    end

    it "measures the distance to another pitch as a chromatic interval" do
      expect(described_class.new(pitch("E4"), pitch("C4")).difference)
        .to eq HeadMusic::Rudiment::ChromaticInterval.get(4)
    end

    it "measures a descending distance as a negative interval" do
      expect(described_class.new(pitch("C4"), pitch("E4")).difference.to_i).to eq(-4)
    end
  end
end
