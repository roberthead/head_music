require "spec_helper"

describe HeadMusic::Notation::Kern::PitchReader do
  def pitch(letters, accidental = "")
    described_class.pitch(letters, accidental).to_s
  end

  {
    ["c", ""] => "C4", ["cc", ""] => "C5", ["ccc", ""] => "C6",
    ["C", ""] => "C3", ["CC", ""] => "C2", ["b", ""] => "B4", ["BB", ""] => "B2",
    ["c", "#"] => "C♯4", ["c", "##"] => "C𝄪4", ["e", "-"] => "E♭4", ["E", "--"] => "E𝄫3", ["f", "n"] => "F4"
  }.each do |(letters, accidental), expected|
    it "reads #{letters}#{accidental} as #{expected}" do
      expect(pitch(letters, accidental)).to eq expected
    end
  end

  it "raises for an accidental it does not recognize" do
    expect { described_class.pitch("c", "###", line_number: 4) }
      .to raise_error(HeadMusic::Notation::Kern::ParseError, /Unrecognized accidental "###" \(line 4\)/)
  end

  it "raises for a register out of range" do
    expect { described_class.pitch("c" * 20, "") }.to raise_error(HeadMusic::Notation::Kern::ParseError, /out of range/)
  end
end
