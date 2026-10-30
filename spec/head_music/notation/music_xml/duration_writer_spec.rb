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
          HeadMusic::Rudiment::RhythmicDuration.get("half tied to eighth")
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
          HeadMusic::Rudiment::RhythmicDuration.get("quarter tied to eighth tied to eighth")
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
          unit: unit, dots: 0, tied_value: nil, unit_name: "whatsit", to_s: "whatsit", written_fraction: Rational(1), link_fraction: Rational(1)
        )
      end

      before { allow(value).to receive(:tied_chain).and_return([value]) }

      it "raises a render error" do
        expect { writer.components(value) }
          .to raise_error(HeadMusic::Notation::MusicXML::RenderError, /no MusicXML note type/)
      end
    end
  end

  describe ".sounding_quarter_fraction" do
    it "takes a triplet eighth as a third of a quarter" do
      value = HeadMusic::Rudiment::RhythmicValue.get("triplet eighth")
      expect(described_class.sounding_quarter_fraction(value)).to eq Rational(1, 3)
    end

    it "takes a 7:4 sixteenth as a seventh of a quarter" do
      value = HeadMusic::Rudiment::RhythmicValue.get("7:4 sixteenth")
      expect(described_class.sounding_quarter_fraction(value)).to eq Rational(1, 7)
    end
  end

  describe "#components of a tuplet value" do
    let(:divisions) { 6 }

    it "writes its sounding duration under its written type" do
      value = HeadMusic::Rudiment::RhythmicValue.get("triplet dotted eighth")
      expect(writer.components(value).first).to have_attributes(duration: 3, type: "eighth", dots: 1)
    end

    it "writes each link of a chain mixing ratios under its own" do
      value = HeadMusic::Rudiment::RhythmicDuration.get("triplet eighth tied to quarter")
      expect(writer.components(value).map(&:duration)).to eq [2, 6]
    end
  end

  describe "#split_components" do
    let(:divisions) { 2 }
    let(:pieces) do
      writer.split_components([
        HeadMusic::Rudiment::RhythmicDuration.get(:half),
        HeadMusic::Rudiment::RhythmicDuration.get("quarter tied to eighth")
      ])
    end

    it "keeps one list of components per piece" do
      expect(pieces.map { |components| components.map(&:type) }).to eq [%w[half], %w[quarter eighth]]
    end

    it "ties through the pieces as one chain" do
      flags = pieces.flatten.map { |component| [component.tie_start, component.tie_stop] }
      expect(flags).to eq [[true, false], [true, true], [false, true]]
    end
  end
end
