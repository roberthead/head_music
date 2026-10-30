require "spec_helper"

describe HeadMusic::Notation::DottedDuration do
  describe ".dotted_unit_fraction" do
    it "is the unit's fraction of a whole note for an undotted value" do
      expect(described_class.dotted_unit_fraction(HeadMusic::Rudiment::RhythmicValue.get(:quarter))).to eq Rational(1, 4)
    end

    it "adds half again for one dot" do
      value = HeadMusic::Rudiment::RhythmicValue.get("dotted half")
      expect(described_class.dotted_unit_fraction(value)).to eq Rational(3, 4)
    end
  end

  describe ".tied" do
    def value(name)
      HeadMusic::Rudiment::RhythmicValue.get(name)
    end

    it "ties the values together in order" do
      expect(described_class.tied([value("half"), value("quarter"), value("eighth")]).to_s).to eq "half tied to quarter tied to eighth"
    end

    it "keeps a duration's own ties inside the whole" do
      head = described_class.rhythmic_duration_for(Rational(5, 4))
      expect(described_class.tied([head, value("half")]).to_s).to eq "whole tied to quarter tied to half"
    end

    it "answers a lone value as it is" do
      expect(described_class.tied([value("quarter")]).to_s).to eq "quarter"
    end
  end

  describe ".rhythmic_duration_for" do
    {
      1 => "whole",
      Rational(1, 4) => "quarter",
      Rational(3, 4) => "dotted half",
      Rational(7, 8) => "double-dotted half",
      Rational(15, 16) => "triple-dotted half",
      Rational(5, 4) => "whole tied to quarter",
      Rational(9, 8) => "whole tied to eighth",
      2 => "double whole",
      8 => "maxima"
    }.each do |fraction, name|
      it "resolves #{fraction} to a #{name}" do
        expect(described_class.rhythmic_duration_for(fraction).to_s).to eq name
      end
    end

    it "accepts an integer" do
      expect(described_class.rhythmic_duration_for(4).to_s).to eq "longa"
    end

    it "answers one value where no tie is needed, as .rhythmic_value_for does" do
      expect(described_class.rhythmic_value_for(Rational(3, 4))).to eq HeadMusic::Rudiment::RhythmicValue.get("dotted half")
    end

    it "leaves .rhythmic_value_for nil where a tie is needed" do
      expect(described_class.rhythmic_value_for(Rational(5, 4))).to be_nil
    end

    it "is nil for a fraction with a non-binary denominator" do
      expect(described_class.rhythmic_value_for(Rational(1, 3))).to be_nil
    end

    it "is nil for a fraction longer than a maxima" do
      expect(described_class.rhythmic_value_for(9)).to be_nil
    end

    it "is nil for zero" do
      expect(described_class.rhythmic_value_for(0)).to be_nil
    end

    it "is nil for a fraction shorter than the smallest unit" do
      expect(described_class.rhythmic_value_for(Rational(1, 1024))).to be_nil
    end

    it "inverts dotted_unit_fraction for every dotted unit" do
      %w[whole half quarter eighth sixteenth].product((0..3).to_a).each do |unit, dots|
        value = HeadMusic::Rudiment::RhythmicValue.new(unit, dots: dots)
        expect(described_class.rhythmic_value_for(described_class.dotted_unit_fraction(value))).to eq value
      end
    end
  end

  describe "tuplet values" do
    let(:triplet_quarter) { HeadMusic::Rudiment::RhythmicValue.get(:quarter, tuplet: "3:2") }

    it "answers a tuplet value's written fraction, leaving out its ratio" do
      expect(described_class.dotted_unit_fraction(triplet_quarter)).to eq Rational(1, 4)
    end

    it "answers a tuplet value's sounding fraction, under its ratio" do
      expect(described_class.sounding_fraction(triplet_quarter)).to eq Rational(1, 6)
    end

    it "builds a value under a ratio from its sounding fraction" do
      expect(described_class.rhythmic_value_for(Rational(1, 12), tuplet: "3:2").to_s).to eq "triplet eighth"
    end

    it "puts the ratio on every link of a chain it builds" do
      expect(described_class.rhythmic_duration_for(Rational(5, 28), tuplet: "7:4").to_s).to eq "7:4 quarter tied to 7:4 sixteenth"
    end

    it "answers nil where no value fits under the ratio" do
      expect(described_class.rhythmic_value_for(Rational(1, 16), tuplet: "2:3")).to be_nil
    end
  end

  describe ".tuplet_ratio" do
    {
      Rational(1, 12) => "3:2",
      Rational(1, 20) => "5:4",
      Rational(3, 10) => "5:3",
      Rational(1, 28) => "7:4"
    }.each do |fraction, ratio|
      it "infers #{ratio} for #{fraction}" do
        expect(described_class.tuplet_ratio(fraction).to_a.join(":")).to eq ratio
      end
    end

    it "answers nil for a binary fraction" do
      expect(described_class.tuplet_ratio(Rational(3, 8))).to be_nil
    end
  end

  describe ".rest_value" do
    it "answers a plain value where one spans the fraction" do
      expect(described_class.rest_duration(Rational(3, 4)).to_s).to eq "dotted half"
    end

    it "answers a value under the implied ratio where none does" do
      expect(described_class.rest_duration(Rational(1, 6)).to_s).to eq "triplet quarter"
    end
  end
end
