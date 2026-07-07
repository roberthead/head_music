require "spec_helper"

describe HeadMusic::Notation::MusicXML::PitchWriter do
  def pitch(name)
    HeadMusic::Rudiment::Pitch.get(name)
  end

  describe ".attributes" do
    it "omits alter for a natural pitch at middle C" do
      expect(described_class.attributes(pitch("C4"))).to eq(step: "C", alter: nil, octave: 4)
    end

    it "reports +1 for a sharp" do
      expect(described_class.attributes(pitch("F#5"))).to eq(step: "F", alter: 1, octave: 5)
    end

    it "reports -1 for a flat" do
      expect(described_class.attributes(pitch("Bb2"))).to eq(step: "B", alter: -1, octave: 2)
    end

    it "reports +2 for a double sharp" do
      expect(described_class.attributes(pitch("Fx4"))).to eq(step: "F", alter: 2, octave: 4)
    end

    it "reports -2 for a double flat" do
      expect(described_class.attributes(pitch("Bbb3"))).to eq(step: "B", alter: -2, octave: 3)
    end

    it "reports the lowest supported register" do
      expect(described_class.attributes(pitch("C0"))).to eq(step: "C", alter: nil, octave: 0)
    end

    it "reports a high register" do
      expect(described_class.attributes(pitch("B8"))).to eq(step: "B", alter: nil, octave: 8)
    end

    it "reports every natural letter name" do
      %w[A B C D E F G].each do |letter|
        expect(described_class.attributes(pitch("#{letter}4"))[:step]).to eq(letter)
      end
    end
  end
end
