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
      expect([result.rhythmic_value.to_s, result.fraction]).to eq [name, fraction]
    end
  end

  %w[3 6 12 24].each do |recip|
    it "raises an unsupported-feature error for the tuplet duration #{recip}" do
      expect { duration(recip) }
        .to raise_error(HeadMusic::Notation::Kern::UnsupportedFeatureError, /Tuplet durations.*\(#{recip}c\) \(line 2\)/)
    end
  end

  it "raises an unsupported-feature error for a non-dyadic rational duration" do
    expect { duration("3%2") }.to raise_error(HeadMusic::Notation::Kern::UnsupportedFeatureError, /Tuplet/)
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
