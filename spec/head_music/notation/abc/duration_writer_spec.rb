require "spec_helper"

describe HeadMusic::Notation::ABC::DurationWriter do
  subject(:writer) { described_class.new(unit_note_length) }

  context "with a unit note length of an eighth" do
    let(:unit_note_length) { Rational(1, 8) }

    {
      ["eighth", 0] => "",
      ["quarter", 0] => "2",
      ["half", 0] => "4",
      ["whole", 0] => "8",
      ["sixteenth", 0] => "1/2",
      ["thirty-second", 0] => "1/4",
      ["quarter", 1] => "3",
      ["eighth", 1] => "3/2",
      ["quarter", 2] => "7/2"
    }.each do |(unit, dots), expected|
      dot_label = (dots > 0) ? " with #{dots} dot(s)" : ""

      it "writes a #{unit}#{dot_label} as #{expected.inspect}" do
        value = HeadMusic::Rudiment::RhythmicValue.new(unit, dots: dots)
        expect(writer.multiplier_string(value)).to eq expected
      end
    end

    context "with a tied chain summing to five eighths" do
      subject(:value) { resolver.rhythmic_value("5") }

      let(:resolver) { HeadMusic::Notation::ABC::DurationResolver.new(unit_note_length) }

      it "arrives from the resolver as a tied chain" do
        expect(value.tied_value).not_to be_nil
      end

      it "collapses the chain back to a single multiplier" do
        expect(writer.multiplier_string(value)).to eq "5"
      end
    end

    describe "round-tripping through the resolver" do
      let(:resolver) { HeadMusic::Notation::ABC::DurationResolver.new(unit_note_length) }

      ["", "2", "3", "1/2", "3/2", "5", "7/2"].each do |multiplier|
        it "returns #{multiplier.inspect} unchanged" do
          value = resolver.rhythmic_value(multiplier)
          expect(writer.multiplier_string(value)).to eq multiplier
        end
      end
    end

    it "raises for a duration longer than a maxima" do
      value = HeadMusic::Rudiment::RhythmicValue.new(
        :maxima, tied_value: HeadMusic::Rudiment::RhythmicValue.new(:maxima)
      )
      expect { writer.multiplier_string(value) }
        .to raise_error(HeadMusic::Notation::ABC::RenderError, /exceeds 8 whole notes/)
    end

    context "with a duration not expressible in binary note values" do
      let(:unit) { instance_double(HeadMusic::Rudiment::RhythmicUnit, numerator: 1, denominator: 3) }
      let(:value) { instance_double(HeadMusic::Rudiment::RhythmicValue, unit: unit, dots: 0, tied_value: nil) }

      it "raises a render error" do
        expect { writer.multiplier_string(value) }
          .to raise_error(HeadMusic::Notation::ABC::RenderError, /not expressible in binary note values/)
      end
    end
  end

  context "with a unit note length of a sixteenth" do
    let(:unit_note_length) { Rational(1, 16) }

    it "writes a sixteenth as an empty multiplier" do
      value = HeadMusic::Rudiment::RhythmicValue.new(:sixteenth)
      expect(writer.multiplier_string(value)).to eq ""
    end

    it "writes a dotted eighth as '3'" do
      value = HeadMusic::Rudiment::RhythmicValue.new(:eighth, dots: 1)
      expect(writer.multiplier_string(value)).to eq "3"
    end
  end
end
