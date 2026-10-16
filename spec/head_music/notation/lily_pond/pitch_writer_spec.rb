require "spec_helper"

describe HeadMusic::Notation::LilyPond::PitchWriter do
  describe ".token" do
    {
      "C4" => "c'",
      "C3" => "c",
      "E2" => "e,",
      "B0" => "b,,,",
      "C7" => "c''''",
      "F#4" => "fis'",
      "Bb3" => "bes",
      "Ab4" => "aes'",
      "Eb5" => "ees''",
      "C##4" => "cisis'",
      "Fbb3" => "feses"
    }.each do |pitch, expected|
      it "renders #{pitch} as #{expected}" do
        expect(described_class.token(pitch)).to eq expected
      end
    end
  end

  describe ".chord" do
    def chord(names, **options)
      described_class.chord(names.map { |name| HeadMusic::Rudiment::Pitch.get(name) }, **options)
    end

    it "writes the members low to high" do
      expect(chord(%w[G4 C4 F#4])).to eq "<c' fis' g'>"
    end

    it "forces the accidentals of members at one letter and octave, highest first" do
      expect(chord(%w[F4 A4 F#4 F5])).to eq "<fis'! f'! a' f''>"
    end

    it "keeps the order but drops the signs when not forced" do
      expect(chord(%w[Bb4 B4], forced: false)).to eq "<b' bes'>"
    end
  end

  describe ".alteration_suffix" do
    it "treats nil as natural" do
      expect(described_class.alteration_suffix(nil)).to eq ""
    end

    it "raises a render error for an alteration beyond double" do
      expect { described_class.alteration_suffix(3) }
        .to raise_error(HeadMusic::Notation::LilyPond::RenderError, /alteration/)
    end
  end
end
