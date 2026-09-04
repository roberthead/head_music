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

    it "ignores a tied value" do
      value = HeadMusic::Rudiment::RhythmicValue.get("half tied to eighth")
      expect(described_class.dotted_unit_fraction(value)).to eq Rational(1, 2)
    end
  end

  describe ".rhythmic_value_for" do
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
        expect(described_class.rhythmic_value_for(fraction).to_s).to eq name
      end
    end

    it "accepts an integer" do
      expect(described_class.rhythmic_value_for(4).to_s).to eq "longa"
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
end
