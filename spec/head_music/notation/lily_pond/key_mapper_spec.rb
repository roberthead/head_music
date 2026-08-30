require "spec_helper"

describe HeadMusic::Notation::LilyPond::KeyMapper do
  describe ".token" do
    {
      "C major" => "\\key c \\major",
      "G major" => "\\key g \\major",
      "F# minor" => "\\key fis \\minor",
      "Bb major" => "\\key bes \\major",
      "Ab major" => "\\key aes \\major",
      "G# major" => "\\key gis \\major",
      "D dorian" => "\\key d \\dorian",
      "E phrygian" => "\\key e \\phrygian",
      "F lydian" => "\\key f \\lydian",
      "G mixolydian" => "\\key g \\mixolydian",
      "B locrian" => "\\key b \\locrian"
    }.each do |key, expected|
      it "renders #{key} as #{expected}" do
        expect(described_class.token(key)).to eq expected
      end
    end

    it "raises a render error for a scale type without a LilyPond mode" do
      key_signature = HeadMusic::Rudiment::KeySignature.get("C harmonic_minor")
      expect { described_class.token(key_signature) }
        .to raise_error(HeadMusic::Notation::LilyPond::RenderError, /scale type/i)
    end
  end
end
