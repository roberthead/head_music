require "spec_helper"

describe HeadMusic::Notation::Kern::DurationReader do
  def duration(recip, dots = "")
    described_class.duration(recip, dots, line_number: 2, snippet: "#{recip}#{dots}c")
  end

  {
    ["1", ""] => ["whole", Rational(1)], ["4", ""] => ["quarter", Rational(1, 4)],
    ["8", "."] => ["dotted eighth", Rational(3, 16)], ["2", ".."] => ["double-dotted half", Rational(7, 8)],
    ["16", "..."] => ["triple-dotted sixteenth", Rational(15, 128)],
    ["0", ""] => ["double whole", Rational(2)], ["00", ""] => ["longa", Rational(4)], ["0", "."] => ["dotted double whole", Rational(3)],
    ["1%2", ""] => ["double whole", Rational(2)], ["2%3", ""] => ["dotted whole", Rational(3, 2)],
    ["8%5", ""] => ["half tied to eighth", Rational(5, 8)]
  }.each do |(recip, dots), (name, fraction)|
    it "reads #{recip}#{dots} as a #{name}" do
      result = duration(recip, dots)
      expect([result.rhythmic_duration.to_s, result.fraction]).to eq [name, fraction]
    end
  end

  describe "tuplet durations" do
    {
      ["3", ""] => ["triplet half", Rational(1, 3)], ["6", ""] => ["triplet quarter", Rational(1, 6)],
      ["12", ""] => ["triplet eighth", Rational(1, 12)], ["24", ""] => ["triplet sixteenth", Rational(1, 24)],
      ["20", ""] => ["5:4 sixteenth", Rational(1, 20)], ["28", ""] => ["7:4 sixteenth", Rational(1, 28)],
      ["112", ""] => ["7:4 sixty-fourth", Rational(1, 112)], ["9", ""] => ["9:8 eighth", Rational(1, 9)],
      ["3%2", ""] => ["triplet whole", Rational(2, 3)], ["10%3", ""] => ["5:3 half", Rational(3, 10)],
      ["12", "."] => ["triplet dotted eighth", Rational(1, 8)], ["6", ".."] => ["triplet double-dotted quarter", Rational(7, 24)],
      ["12%5", ""] => ["triplet half tied to triplet eighth", Rational(5, 12)]
    }.each do |(recip, dots), (name, fraction)|
      it "reads #{recip}#{dots} as a #{name}" do
        result = duration(recip, dots)
        expect([result.rhythmic_duration.to_s, result.fraction, result.rhythmic_duration.fraction]).to eq [name, fraction, fraction]
      end
    end

    it "reads a duplet, which sounds as a dotted value, as that value" do
      expect(duration("8", ".").rhythmic_duration).not_to be_tuplet
    end

    it "raises an unsupported-feature error for a tuplet unit shorter than a 256th" do
      expect { duration("1536") }
        .to raise_error(HeadMusic::Notation::Kern::UnsupportedFeatureError, /3:2 tuplet value in 1536c is outside.*\(line 2\)/)
    end
  end

  it "raises for too many dots" do
    expect { duration("4", "....") }.to raise_error(HeadMusic::Notation::Kern::ParseError, /Too many dots/)
  end

  it "raises for a reciprocal too short to name" do
    expect { duration("4096") }.to raise_error(HeadMusic::Notation::Kern::ParseError, /Unrecognized duration "4096"/)
  end

  it "raises for a rational duration too long to name" do
    expect { duration("1%16") }.to raise_error(HeadMusic::Notation::Kern::ParseError, /Unrecognized duration/)
  end

  it "raises for a zero in a rational duration" do
    expect { duration("0%1") }.to raise_error(HeadMusic::Notation::Kern::ParseError, /Unrecognized duration "0"/)
  end
end
