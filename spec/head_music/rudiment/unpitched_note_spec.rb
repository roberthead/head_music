require "spec_helper"

describe HeadMusic::Rudiment::UnpitchedNote do
  describe ".get" do
    context "with just a rhythmic value" do
      subject(:note) { described_class.get(:quarter) }

      it "creates an unpitched note with the specified rhythmic value" do
        expect(note).to be_a(described_class)
        expect(note.rhythmic_value).to eq(HeadMusic::Content::RhythmicValue.get(:quarter))
        expect(note.instrument_name).to be_nil
      end
    end

    context "with rhythmic value and instrument name" do
      subject(:note) { described_class.get(:eighth, instrument: "snare drum") }

      it "creates an unpitched note with both properties" do
        expect(note).to be_a(described_class)
        expect(note.rhythmic_value.unit.name).to eq("eighth")
        expect(note.instrument_name).to eq("snare drum")
      end
    end

    context "with a RhythmicValue object" do
      subject(:note) { described_class.get(rhythmic_value, instrument: "bass drum") }

      let(:rhythmic_value) { HeadMusic::Content::RhythmicValue.get(:sixteenth) }

      it "creates an unpitched note with the specified values" do
        expect(note).to be_a(described_class)
        expect(note.rhythmic_value).to eq(rhythmic_value)
        expect(note.instrument_name).to eq("bass drum")
      end
    end

    context "when given an existing UnpitchedNote" do
      subject(:note) { described_class.get(original_note) }

      let(:original_note) { described_class.get(:whole, instrument: "cymbal") }

      it "returns the same unpitched note" do
        expect(note).to be(original_note)
      end
    end
  end

  describe "#name" do
    context "without instrument name" do
      subject(:note) { described_class.get(:quarter) }

      it "returns a string representation" do
        expect(note.name).to eq("quarter unpitched note")
      end
    end

    context "with instrument name" do
      subject(:note) { described_class.get(:half, instrument: "hi-hat") }

      it "includes the instrument name" do
        expect(note.name).to eq("half hi-hat")
      end
    end
  end

  describe "#to_s" do
    subject(:note) { described_class.get(:whole, instrument: "timpani") }

    it "returns the name" do
      expect(note.to_s).to eq("whole timpani")
    end
  end

  describe "#==" do
    let(:quarter_snare) { described_class.get(:quarter, instrument: "snare drum") }
    let(:another_quarter_snare) { described_class.get(:quarter, instrument: "snare drum") }
    let(:quarter_bass) { described_class.get(:quarter, instrument: "bass drum") }
    let(:half_snare) { described_class.get(:half, instrument: "snare drum") }
    let(:quarter_no_instrument) { described_class.get(:quarter) }

    it "returns true for notes with same rhythmic value and instrument" do
      expect(quarter_snare).to eq(another_quarter_snare)
    end

    it "returns false for notes with different instruments" do
      expect(quarter_snare).not_to eq(quarter_bass)
    end

    it "returns false for notes with different rhythmic values" do
      expect(quarter_snare).not_to eq(half_snare)
    end

    it "returns false when one has instrument and other doesn't" do
      expect(quarter_snare).not_to eq(quarter_no_instrument)
    end

    it "returns false when comparing with a non-unpitched-note" do
      expect(quarter_snare).not_to eq("quarter snare drum")
    end
  end

  describe "#with_rhythmic_value" do
    let(:quarter_snare) { described_class.get(:quarter, instrument: "snare drum") }
    let(:new_note) { quarter_snare.with_rhythmic_value(:half) }

    it "creates a new unpitched note with the same instrument" do
      expect(new_note).to be_a(described_class)
      expect(new_note.rhythmic_value).to eq(HeadMusic::Content::RhythmicValue.get(:half))
      expect(new_note.instrument_name).to eq("snare drum")
      expect(new_note).not_to eq(quarter_snare)
    end
  end

  describe "#with_instrument" do
    let(:quarter_snare) { described_class.get(:quarter, instrument: "snare drum") }
    let(:new_note) { quarter_snare.with_instrument("bass drum") }

    it "creates a new unpitched note with the same rhythmic value" do
      expect(new_note).to be_a(described_class)
      expect(new_note.rhythmic_value).to eq(HeadMusic::Content::RhythmicValue.get(:quarter))
      expect(new_note.instrument_name).to eq("bass drum")
      expect(new_note).not_to eq(quarter_snare)
    end
  end

  describe "inheritance" do
    it "inherits from MusicalElement" do
      expect(described_class.ancestors).to include(HeadMusic::Rudiment::MusicalElement)
    end
  end

  describe "delegation" do
    subject(:note) { described_class.get("dotted eighth", instrument: "cowbell") }

    it "delegates rhythmic value methods" do
      expect(note.unit.name).to eq("eighth")
      expect(note.dots).to eq(1)
      expect(note.ticks).to be > 0
    end
  end

  describe "#sounded?" do
    subject(:note) { described_class.get(:quarter, instrument: "snare drum") }

    it "returns true for unpitched notes" do
      expect(note.sounded?).to be true
    end
  end
end
