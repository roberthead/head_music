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
