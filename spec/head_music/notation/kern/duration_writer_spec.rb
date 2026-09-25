require "spec_helper"

describe HeadMusic::Notation::Kern::DurationWriter do
  {
    ["whole", 0] => "1", ["half", 0] => "2", ["quarter", 1] => "4.", ["eighth", 2] => "8..",
    ["sixteenth", 0] => "16", ["double whole", 0] => "0", ["double whole", 1] => "0.", ["longa", 0] => "00"
  }.each do |(unit, dots), token|
    rhythmic_value = HeadMusic::Rudiment::RhythmicValue.new(HeadMusic::Rudiment::RhythmicUnit.get(unit), dots: dots)

    it "writes #{rhythmic_value} as #{token}" do
      expect(described_class.token(rhythmic_value)).to eq token
    end

    it "reads #{token} back as #{rhythmic_value}" do
      recip, dot_marks = token.match(/\A(\d+)(\.*)\z/).captures
      expect(HeadMusic::Notation::Kern::DurationReader.duration(recip, dot_marks).rhythmic_value).to eq rhythmic_value
    end
  end
end
