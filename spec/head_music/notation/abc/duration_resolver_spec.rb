require "spec_helper"

describe HeadMusic::Notation::ABC::DurationResolver do
  subject(:resolver) { described_class.new(unit_note_length) }

  context "with a unit note length of an eighth" do
    let(:unit_note_length) { Rational(1, 8) }

    {
      "" => ["eighth", 0],
      "2" => ["quarter", 0],
      "4" => ["half", 0],
      "8" => ["whole", 0],
      "16" => ["double whole", 0],
      "3" => ["quarter", 1],
      "/" => ["sixteenth", 0],
      "/2" => ["sixteenth", 0],
      "//" => ["thirty-second", 0],
      "3/2" => ["eighth", 1],
      "7" => ["half", 2],
      "15" => ["whole", 3]
    }.each do |multiplier, (expected_unit, expected_dots)|
      context "with a multiplier of #{multiplier.inspect}" do
        subject(:value) { resolver.rhythmic_value(multiplier) }

        it "selects the #{expected_unit} unit" do
          expect(value.unit_name).to eq expected_unit
        end

        it "applies #{expected_dots} dot(s)" do
          expect(value.dots).to eq expected_dots
        end

        it "does not tie to another value" do
          expect(value.tied_value).to be_nil
        end
      end
    end

    context "with a multiplier of '5'" do
      subject(:value) { resolver.rhythmic_value("5") }

      it "selects a half note head" do
        expect(value.unit_name).to eq "half"
      end

      it "ties to an eighth note" do
        expect(value.tied_value.unit_name).to eq "eighth"
      end

      it "totals five eighths of a whole note" do
        expected = HeadMusic::Rudiment::RhythmicValue.new(
          :half, tied_value: HeadMusic::Rudiment::RhythmicValue.new(:eighth)
        )
        expect(value.total_value).to eq expected.total_value
      end
    end

    it "raises for a non-power-of-two total duration" do
      expect { resolver.rhythmic_value("1/3") }.to raise_error(HeadMusic::Notation::ABC::ParseError)
    end

    it "raises for a malformed multiplier" do
      expect { resolver.rhythmic_value("x2") }.to raise_error(HeadMusic::Notation::ABC::ParseError)
    end

    it "raises for a multiple-slash multiplier with an explicit denominator" do
      expect { resolver.rhythmic_value("3//2") }.to raise_error(HeadMusic::Notation::ABC::ParseError)
    end

    it "raises for a zero multiplier" do
      expect { resolver.rhythmic_value("0") }.to raise_error(HeadMusic::Notation::ABC::ParseError)
    end

    it "raises for a zero denominator" do
      expect { resolver.rhythmic_value("1/0") }.to raise_error(HeadMusic::Notation::ABC::ParseError)
    end

    it "raises for a duration longer than a maxima" do
      expect { resolver.rhythmic_value("128") }.to raise_error(HeadMusic::Notation::ABC::ParseError)
    end

    describe "the scale parameter" do
      it "dots the value with a scale of 3/2" do
        value = resolver.rhythmic_value("", scale: Rational(3, 2))
        expect([value.unit_name, value.dots]).to eq ["eighth", 1]
      end

      it "halves the value with a scale of 1/2" do
        value = resolver.rhythmic_value("", scale: Rational(1, 2))
        expect([value.unit_name, value.dots]).to eq ["sixteenth", 0]
      end

      it "applies the scale after the multiplier" do
        value = resolver.rhythmic_value("2", scale: Rational(3, 2))
        expect([value.unit_name, value.dots]).to eq ["quarter", 1]
      end

      it "raises when the scaled duration is not expressible" do
        expect { resolver.rhythmic_value("", scale: Rational(1, 3)) }
          .to raise_error(HeadMusic::Notation::ABC::ParseError)
      end
    end
  end

  context "with a unit note length of a sixteenth" do
    let(:unit_note_length) { Rational(1, 16) }

    it "resolves an unmarked note to a sixteenth" do
      expect(resolver.rhythmic_value("").unit_name).to eq "sixteenth"
    end

    it "resolves a multiplier of '3' to a dotted eighth" do
      value = resolver.rhythmic_value("3")
      expect([value.unit_name, value.dots]).to eq ["eighth", 1]
    end

    it "resolves a multiplier of '6' to a dotted quarter" do
      value = resolver.rhythmic_value("6")
      expect([value.unit_name, value.dots]).to eq ["quarter", 1]
    end

    it "raises for a duration shorter than the smallest supported unit" do
      expect { resolver.rhythmic_value("1/64") }.to raise_error(HeadMusic::Notation::ABC::ParseError)
    end
  end
end
