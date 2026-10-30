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
      expect(HeadMusic::Notation::Kern::DurationReader.duration(recip, dot_marks).rhythmic_duration.single_value).to eq rhythmic_value
    end
  end

  describe "tuplet values, written by what they sound" do
    {
      "triplet eighth" => "12", "triplet dotted eighth" => "12.", "triplet sixteenth" => "24", "6:4 sixteenth" => "24",
      "5:4 sixteenth" => "20", "7:4 sixteenth" => "28", "triplet whole" => "3%2", "5:3 half" => "10%3",
      "9:8 eighth" => "9", "2:3 eighth" => "8.", "2:3 dotted eighth" => "16%3.", "triplet double whole" => "3%4"
    }.each do |name, token|
      it "writes a #{name} as #{token}" do
        expect(described_class.token(HeadMusic::Rudiment::RhythmicValue.get(name))).to eq token
      end

      it "reads #{token} back at the length of a #{name}" do
        recip, dot_marks = token.match(/\A([\d%]+)(\.*)\z/).captures
        expect(HeadMusic::Notation::Kern::DurationReader.duration(recip, dot_marks).fraction)
          .to eq HeadMusic::Rudiment::RhythmicValue.get(name).fraction
      end
    end
  end
end
