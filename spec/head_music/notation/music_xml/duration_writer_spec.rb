require "spec_helper"

describe HeadMusic::Notation::MusicXML::DurationWriter do
  subject(:writer) { described_class.new(divisions) }

  describe ".single_quarter_fraction" do
    it "returns 4 for a whole note" do
      value = HeadMusic::Rudiment::RhythmicValue.get(:whole)
      expect(described_class.single_quarter_fraction(value)).to eq 4r
    end

    it "returns 3/2 for a dotted quarter" do
      value = HeadMusic::Rudiment::RhythmicValue.get("dotted quarter")
      expect(described_class.single_quarter_fraction(value)).to eq Rational(3, 2)
    end
  end

  describe "#components" do
    context "with divisions of 1" do
      let(:divisions) { 1 }

      it "writes a single quarter note with no ties" do
        value = HeadMusic::Rudiment::RhythmicValue.get(:quarter)
        expect(writer.components(value).first.to_h).to eq(
          duration: 1, type: "quarter", dots: 0, tie_start: false, tie_stop: false
        )
      end

      it "raises for an eighth note, which is not integral at this divisions" do
        value = HeadMusic::Rudiment::RhythmicValue.get(:eighth)
        expect { writer.components(value) }
          .to raise_error(HeadMusic::Notation::MusicXML::RenderError, /eighth/)
      end

      it "maps a double whole note to the breve type at duration 8" do
        value = HeadMusic::Rudiment::RhythmicValue.get(:"double whole")
        expect(writer.components(value).first).to have_attributes(type: "breve", duration: 8)
      end

      it "maps a longa to the long type at duration 16" do
        value = HeadMusic::Rudiment::RhythmicValue.get(:longa)
        expect(writer.components(value).first).to have_attributes(type: "long", duration: 16)
      end
    end

    context "with divisions of 2" do
      let(:divisions) { 2 }

      it "writes a dotted half with 1 dot and duration 6" do
        value = HeadMusic::Rudiment::RhythmicValue.get("dotted half")
        expect(writer.components(value).first).to have_attributes(duration: 6, dots: 1)
      end

      it "writes a double-dotted half with 2 dots and duration 7" do
        value = HeadMusic::Rudiment::RhythmicValue.new(:half, dots: 2)
        expect(writer.components(value).first).to have_attributes(duration: 7, dots: 2)
      end

      context "with a 2-link tied chain (half tied to eighth)" do
        let(:value) do
          HeadMusic::Rudiment::RhythmicValue.new(:half, tied_value: HeadMusic::Rudiment::RhythmicValue.get(:eighth))
        end
        let(:components) { writer.components(value) }

        it "produces one component per link with durations [4, 1]" do
          expect(components.map(&:duration)).to eq [4, 1]
        end

        it "starts a tie on every link but the last" do
          expect(components.map(&:tie_start)).to eq [true, false]
        end

        it "stops a tie on every link but the first" do
          expect(components.map(&:tie_stop)).to eq [false, true]
        end
      end

      context "with a 3-link tied chain (quarter tied to eighth tied to eighth)" do
        let(:value) do
          last = HeadMusic::Rudiment::RhythmicValue.get(:eighth)
          middle = HeadMusic::Rudiment::RhythmicValue.new(:eighth, tied_value: last)
          HeadMusic::Rudiment::RhythmicValue.new(:quarter, tied_value: middle)
        end
        let(:components) { writer.components(value) }

        it "produces durations [2, 1, 1]" do
          expect(components.map(&:duration)).to eq [2, 1, 1]
        end

        it "gives the middle link both tie flags" do
          expect(components.map { |c| [c.tie_start, c.tie_stop] }).to eq [[true, false], [true, true], [false, true]]
        end
      end
    end

    context "with divisions of 4" do
      let(:divisions) { 4 }

      it "writes a triple-dotted half with 3 dots and duration 15" do
        value = HeadMusic::Rudiment::RhythmicValue.new(:half, dots: 3)
        expect(writer.components(value).first).to have_attributes(duration: 15, dots: 3)
      end

      it "maps a sixteenth note to the 16th type at duration 1" do
        value = HeadMusic::Rudiment::RhythmicValue.get(:sixteenth)
        expect(writer.components(value).first).to have_attributes(type: "16th", duration: 1)
      end
    end

    context "with a rhythmic value whose unit has no MusicXML type mapping" do
      let(:divisions) { 1 }
      let(:unit) { instance_double(HeadMusic::Rudiment::RhythmicUnit, numerator: 1, denominator: 1, name: "whatsit") }
      let(:value) do
        instance_double(
          HeadMusic::Rudiment::RhythmicValue,
          unit: unit, dots: 0, tied_value: nil, unit_name: "whatsit", to_s: "whatsit"
        )
      end

      it "raises a render error" do
        expect { writer.components(value) }
          .to raise_error(HeadMusic::Notation::MusicXML::RenderError, /no MusicXML note type/)
      end
    end
  end
end
