require "spec_helper"

describe HeadMusic::Rudiment::Note do
  describe ".get" do
    context "with pitch and rhythmic value arguments" do
      subject(:note) { described_class.get("C#4", "quarter") }

      it "creates a note with the given pitch" do
        expect(note.pitch).to eq HeadMusic::Rudiment::Pitch.get("C#4")
      end

      it "creates a note with the given rhythmic value" do
        expect(note.rhythmic_value).to eq HeadMusic::Rudiment::RhythmicValue.get("quarter")
      end
    end

    context "with a string argument" do
      it "parses 'C#4 quarter'" do
        note = described_class.get("C#4 quarter")
        expect(note.pitch.to_s).to eq "C♯4"
        expect(note.rhythmic_value.to_s).to eq "quarter"
      end

      it "parses 'Eb3 dotted half'" do
        note = described_class.get("Eb3 dotted half")
        expect(note.pitch.to_s).to eq "E♭3"
        expect(note.rhythmic_value.to_s).to eq "dotted half"
      end
    end

    context "when given a Note instance" do
      let(:note) { described_class.get("A4", "eighth") }

      it "returns the same instance" do
        expect(described_class.get(note)).to be note
      end
    end

    context "with only a pitch" do
      it "defaults to quarter note" do
        note = described_class.get("G5")
        expect(note.rhythmic_value.to_s).to eq "quarter"
      end
    end
  end

  describe "#name" do
    subject(:note) { described_class.get("F#5", "sixteenth") }

    it "combines pitch and rhythmic value" do
      expect(note.name).to eq "F♯5 sixteenth"
    end
  end

  describe "#to_s" do
    subject(:note) { described_class.get("Bb2", "whole") }

    it "returns the name" do
      expect(note.to_s).to eq "B♭2 whole"
    end
  end

  describe "equality" do
    let(:middle_c_quarter_note) { described_class.get("C4", "quarter") }
    let(:another_middle_c_quarter_note) { described_class.get("C4", "quarter") }
    let(:different_pitch) { described_class.get("D4", "quarter") }
    let(:different_rhythm) { described_class.get("C4", "half") }

    it "considers notes with same pitch and rhythm equal" do
      expect(middle_c_quarter_note).to eq another_middle_c_quarter_note
    end

    it "considers notes with different pitches unequal" do
      expect(middle_c_quarter_note).not_to eq different_pitch
    end

    it "considers notes with different rhythms unequal" do
      expect(middle_c_quarter_note).not_to eq different_rhythm
    end
  end

  describe "comparison" do
    let(:c4_quarter) { described_class.get("C4", "quarter") }
    let(:c4_half) { described_class.get("C4", "half") }
    let(:d4_quarter) { described_class.get("D4", "quarter") }
    let(:d4_half) { described_class.get("D4", "half") }

    it "compares by rhythmic value first" do
      # Quarter notes come before half notes regardless of pitch
      expect(c4_quarter).to be < c4_half
      expect(d4_quarter).to be < d4_half
      expect(d4_quarter).to be < c4_half  # D4 quarter < C4 half
    end

    it "uses pitch as tie-breaker when rhythmic values are equal" do
      # When rhythmic values are equal, pitch determines order
      expect(c4_quarter).to be < d4_quarter
    end
  end

  describe "transposition" do
    let(:note) { described_class.get("C4", "quarter") }

    describe "#+" do
      it "transposes up by semitones" do
        transposed = note + 3
        expect(transposed.pitch.to_s).to eq "D♯4"
        expect(transposed.rhythmic_value).to eq note.rhythmic_value
      end
    end

    describe "#-" do
      it "transposes down by semitones" do
        transposed = note - 2
        expect(transposed.pitch.to_s).to eq "A♯3"
        expect(transposed.rhythmic_value).to eq note.rhythmic_value
      end
    end
  end

  describe "#with_rhythmic_value" do
    let(:note) { described_class.get("A4", "quarter") }

    it "returns a new note with the same pitch but different rhythm" do
      new_note = note.with_rhythmic_value("eighth")
      expect(new_note.pitch).to eq note.pitch
      expect(new_note.rhythmic_value.to_s).to eq "eighth"
    end
  end

  describe "#with_pitch" do
    let(:note) { described_class.get("A4", "quarter") }

    it "returns a new note with the same rhythm but different pitch" do
      new_note = note.with_pitch("F#3")
      expect(new_note.pitch.to_s).to eq "F♯3"
      expect(new_note.rhythmic_value).to eq note.rhythmic_value
    end
  end

  describe "delegation to pitch" do
    let(:note) { described_class.get("G#5", "half") }

    it "delegates pitch methods" do
      expect(note.spelling.to_s).to eq "G♯"
      expect(note.register).to eq 5
      expect(note.sharp?).to be true
      expect(note.flat?).to be false
    end
  end

  describe "delegation to rhythmic_value" do
    let(:note) { described_class.get("C4", "dotted quarter") }

    it "delegates rhythmic value methods" do
      expect(note.dots).to eq 1
      expect(note.unit.to_s).to eq "quarter"
    end
  end

  describe "Parsable integration" do
    it "parses note strings" do
      note = described_class.parse("Ab3 sixteenth")
      expect(note.pitch.to_s).to eq "A♭3"
      expect(note.rhythmic_value.to_s).to eq "sixteenth"
    end

    it "returns nil for invalid strings" do
      expect(described_class.parse("invalid")).to be_nil
    end
  end

  describe "Named integration" do
    let(:note) { described_class.get("D5", "whole") }

    it "provides a name" do
      expect(note.name).to eq "D5 whole"
    end
  end

  describe "#sounded?" do
    let(:note) { described_class.get("C4", "quarter") }

    it "returns true for notes" do
      expect(note.sounded?).to be true
    end
  end
end
