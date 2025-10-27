require "spec_helper"

describe HeadMusic::Analysis::DiatonicInterval do
  describe "#consonance_classification" do
    context "with default modern style" do
      it "classifies unison as perfect consonance" do
        interval = described_class.new("C4", "C4")
        expect(interval.consonance_classification).to eq(HeadMusic::Rudiment::Consonance::PERFECT_CONSONANCE)
      end

      it "classifies octave as perfect consonance" do
        interval = described_class.new("C4", "C5")
        expect(interval.consonance_classification).to eq(HeadMusic::Rudiment::Consonance::PERFECT_CONSONANCE)
      end

      it "classifies perfect fifth as perfect consonance" do
        interval = described_class.new("C4", "G4")
        expect(interval.consonance_classification).to eq(HeadMusic::Rudiment::Consonance::PERFECT_CONSONANCE)
      end

      it "classifies major third as imperfect consonance" do
        interval = described_class.new("C4", "E4")
        expect(interval.consonance_classification).to eq(HeadMusic::Rudiment::Consonance::IMPERFECT_CONSONANCE)
      end

      it "classifies minor third as imperfect consonance" do
        interval = described_class.new("C4", "Eb4")
        expect(interval.consonance_classification).to eq(HeadMusic::Rudiment::Consonance::IMPERFECT_CONSONANCE)
      end

      it "classifies major sixth as imperfect consonance" do
        interval = described_class.new("C4", "A4")
        expect(interval.consonance_classification).to eq(HeadMusic::Rudiment::Consonance::IMPERFECT_CONSONANCE)
      end

      it "classifies minor sixth as imperfect consonance" do
        interval = described_class.new("C4", "Ab4")
        expect(interval.consonance_classification).to eq(HeadMusic::Rudiment::Consonance::IMPERFECT_CONSONANCE)
      end

      it "classifies perfect fourth as contextual" do
        interval = described_class.new("C4", "F4")
        expect(interval.consonance_classification).to eq(HeadMusic::Rudiment::Consonance::CONTEXTUAL)
      end

      it "classifies major second as mild dissonance" do
        interval = described_class.new("C4", "D4")
        expect(interval.consonance_classification).to eq(HeadMusic::Rudiment::Consonance::MILD_DISSONANCE)
      end

      it "classifies minor seventh as mild dissonance" do
        interval = described_class.new("C4", "Bb4")
        expect(interval.consonance_classification).to eq(HeadMusic::Rudiment::Consonance::MILD_DISSONANCE)
      end

      it "classifies minor second as harsh dissonance" do
        interval = described_class.new("C4", "Db4")
        expect(interval.consonance_classification).to eq(HeadMusic::Rudiment::Consonance::HARSH_DISSONANCE)
      end

      it "classifies major seventh as harsh dissonance" do
        interval = described_class.new("C4", "B4")
        expect(interval.consonance_classification).to eq(HeadMusic::Rudiment::Consonance::HARSH_DISSONANCE)
      end

      it "classifies tritone (augmented fourth) as dissonance" do
        interval = described_class.new("C4", "F#4")
        expect(interval.consonance_classification).to eq(HeadMusic::Rudiment::Consonance::DISSONANCE)
      end

      it "classifies diminished fifth as dissonance" do
        interval = described_class.new("C4", "Gb4")
        expect(interval.consonance_classification).to eq(HeadMusic::Rudiment::Consonance::DISSONANCE)
      end
    end

    context "with renaissance counterpoint style" do
      it "classifies perfect fourth as dissonance" do
        interval = described_class.new("C4", "F4")
        expect(interval.consonance_classification(style: :renaissance_counterpoint)).to eq(HeadMusic::Rudiment::Consonance::DISSONANCE)
      end

      it "classifies perfect fifth as perfect consonance" do
        interval = described_class.new("C4", "G4")
        expect(interval.consonance_classification(style: :renaissance_counterpoint)).to eq(HeadMusic::Rudiment::Consonance::PERFECT_CONSONANCE)
      end

      it "classifies major third as imperfect consonance" do
        interval = described_class.new("C4", "E4")
        expect(interval.consonance_classification(style: :renaissance_counterpoint)).to eq(HeadMusic::Rudiment::Consonance::IMPERFECT_CONSONANCE)
      end
    end

    context "with medieval style" do
      it "classifies perfect fourth as consonance" do
        interval = described_class.new("C4", "F4")
        expect(interval.consonance_classification(style: :medieval)).to eq(HeadMusic::Rudiment::Consonance::PERFECT_CONSONANCE)
      end
    end
  end

  describe "#consonant?" do
    context "with default modern style" do
      it "returns true for perfect consonances" do
        interval = described_class.new("C4", "G4")
        expect(interval.consonant?).to be true
      end

      it "returns true for imperfect consonances" do
        interval = described_class.new("C4", "E4")
        expect(interval.consonant?).to be true
      end

      it "returns false for mild dissonances" do
        interval = described_class.new("C4", "D4")
        expect(interval.consonant?).to be false
      end

      it "returns false for harsh dissonances" do
        interval = described_class.new("C4", "Db4")
        expect(interval.consonant?).to be false
      end

      it "returns false for tritone" do
        interval = described_class.new("C4", "F#4")
        expect(interval.consonant?).to be false
      end

      it "returns false for perfect fourth in default style (contextual)" do
        interval = described_class.new("C4", "F4")
        expect(interval.consonant?).to be false
      end
    end

    context "with specific style" do
      it "returns false for perfect fourth in renaissance style" do
        interval = described_class.new("C4", "F4")
        expect(interval.consonant?(:renaissance_counterpoint)).to be false
      end

      it "returns true for perfect fourth in medieval style" do
        interval = described_class.new("C4", "F4")
        expect(interval.consonant?(:medieval)).to be true
      end
    end
  end

  describe "#dissonant?" do
    it "returns opposite of consonant?" do
      interval = described_class.new("C4", "G4")
      expect(interval.dissonant?).to eq(!interval.consonant?)
    end

    it "returns true for dissonances" do
      interval = described_class.new("C4", "Db4")
      expect(interval.dissonant?).to be true
    end

    it "returns false for consonances" do
      interval = described_class.new("C4", "E4")
      expect(interval.dissonant?).to be false
    end

    context "with specific style" do
      it "respects the style parameter" do
        interval = described_class.new("C4", "F4")
        expect(interval.dissonant?(:medieval)).to be false
        expect(interval.dissonant?(:renaissance_counterpoint)).to be true
      end
    end
  end
end
