require "spec_helper"

describe HeadMusic::Notation::Kern::PitchWriter do
  {
    "C4" => "c", "C5" => "cc", "B3" => "B", "G2" => "GG",
    "F#5" => "ff#", "Bb2" => "BB-", "Cx4" => "c##", "Ebb3" => "E--"
  }.each do |name, token|
    it "writes #{name} as #{token}" do
      expect(described_class.token(HeadMusic::Rudiment::Pitch.get(name))).to eq token
    end

    it "reads #{token} back as #{name}" do
      letters, accidental = token.match(/\A([a-gA-G]+)(.*)\z/).captures
      expect(HeadMusic::Notation::Kern::PitchReader.pitch(letters, accidental)).to eq HeadMusic::Rudiment::Pitch.get(name)
    end
  end
end
