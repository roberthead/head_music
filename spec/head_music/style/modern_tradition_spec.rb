require "spec_helper"

describe HeadMusic::Style::ModernTradition do
  let(:tradition) { described_class.new }

  describe "#consonance_classification" do
    context "with perfect consonances" do
      it "classifies unison as perfect consonance" do
        interval = HeadMusic::Analysis::DiatonicInterval.get("P1")
        expect(tradition.consonance_classification(interval)).to eq(HeadMusic::Rudiment::Consonance::PERFECT_CONSONANCE)
      end

      it "classifies octave as perfect consonance" do
        interval = HeadMusic::Analysis::DiatonicInterval.get("P8")
        expect(tradition.consonance_classification(interval)).to eq(HeadMusic::Rudiment::Consonance::PERFECT_CONSONANCE)
      end

      it "classifies perfect fifth as perfect consonance" do
        interval = HeadMusic::Analysis::DiatonicInterval.get("P5")
        expect(tradition.consonance_classification(interval)).to eq(HeadMusic::Rudiment::Consonance::PERFECT_CONSONANCE)
      end

      it "classifies perfect fourth as contextual" do
        interval = HeadMusic::Analysis::DiatonicInterval.get("P4")
        expect(tradition.consonance_classification(interval)).to eq(HeadMusic::Rudiment::Consonance::CONTEXTUAL)
      end
    end

    context "with contextual intervals" do
      it "classifies perfect fourth as contextual" do
        interval = HeadMusic::Analysis::DiatonicInterval.get("P4")
        expect(tradition.consonance_classification(interval)).to eq(HeadMusic::Rudiment::Consonance::CONTEXTUAL)
      end
    end

    context "with imperfect consonances" do
      it "classifies major third as imperfect consonance" do
        interval = HeadMusic::Analysis::DiatonicInterval.get("M3")
        expect(tradition.consonance_classification(interval)).to eq(HeadMusic::Rudiment::Consonance::IMPERFECT_CONSONANCE)
      end

      it "classifies minor third as imperfect consonance" do
        interval = HeadMusic::Analysis::DiatonicInterval.get("m3")
        expect(tradition.consonance_classification(interval)).to eq(HeadMusic::Rudiment::Consonance::IMPERFECT_CONSONANCE)
      end

      it "classifies major sixth as imperfect consonance" do
        interval = HeadMusic::Analysis::DiatonicInterval.get("M6")
        expect(tradition.consonance_classification(interval)).to eq(HeadMusic::Rudiment::Consonance::IMPERFECT_CONSONANCE)
      end

      it "classifies minor sixth as imperfect consonance" do
        interval = HeadMusic::Analysis::DiatonicInterval.get("m6")
        expect(tradition.consonance_classification(interval)).to eq(HeadMusic::Rudiment::Consonance::IMPERFECT_CONSONANCE)
      end
    end

    context "with mild dissonances" do
      it "classifies major second as mild dissonance" do
        interval = HeadMusic::Analysis::DiatonicInterval.get("M2")
        expect(tradition.consonance_classification(interval)).to eq(HeadMusic::Rudiment::Consonance::MILD_DISSONANCE)
      end

      it "classifies minor seventh as mild dissonance" do
        interval = HeadMusic::Analysis::DiatonicInterval.get("m7")
        expect(tradition.consonance_classification(interval)).to eq(HeadMusic::Rudiment::Consonance::MILD_DISSONANCE)
      end
    end

    context "with harsh dissonances" do
      it "classifies minor second as harsh dissonance" do
        interval = HeadMusic::Analysis::DiatonicInterval.get("m2")
        expect(tradition.consonance_classification(interval)).to eq(HeadMusic::Rudiment::Consonance::HARSH_DISSONANCE)
      end

      it "classifies major seventh as harsh dissonance" do
        interval = HeadMusic::Analysis::DiatonicInterval.get("M7")
        expect(tradition.consonance_classification(interval)).to eq(HeadMusic::Rudiment::Consonance::HARSH_DISSONANCE)
      end
    end

    context "with dissonances" do
      it "classifies tritone (augmented fourth) as dissonance" do
        interval = HeadMusic::Analysis::DiatonicInterval.get("A4")
        expect(tradition.consonance_classification(interval)).to eq(HeadMusic::Rudiment::Consonance::DISSONANCE)
      end

      it "classifies tritone (diminished fifth) as dissonance" do
        interval = HeadMusic::Analysis::DiatonicInterval.get("d5")
        expect(tradition.consonance_classification(interval)).to eq(HeadMusic::Rudiment::Consonance::DISSONANCE)
      end

      it "classifies augmented second as dissonance" do
        interval = HeadMusic::Analysis::DiatonicInterval.get("A2")
        expect(tradition.consonance_classification(interval)).to eq(HeadMusic::Rudiment::Consonance::DISSONANCE)
      end

      it "classifies diminished third as dissonance" do
        interval = HeadMusic::Analysis::DiatonicInterval.get("d3")
        expect(tradition.consonance_classification(interval)).to eq(HeadMusic::Rudiment::Consonance::DISSONANCE)
      end

      it "classifies augmented fifth as dissonance" do
        interval = HeadMusic::Analysis::DiatonicInterval.get("A5")
        expect(tradition.consonance_classification(interval)).to eq(HeadMusic::Rudiment::Consonance::DISSONANCE)
      end

      it "classifies diminished sixth as dissonance" do
        interval = HeadMusic::Analysis::DiatonicInterval.get("d6")
        expect(tradition.consonance_classification(interval)).to eq(HeadMusic::Rudiment::Consonance::DISSONANCE)
      end
    end

    context "with compound intervals" do
      it "classifies compound intervals based on their simple form" do
        interval = HeadMusic::Analysis::DiatonicInterval.get("M10") # compound major third
        expect(tradition.consonance_classification(interval)).to eq(HeadMusic::Rudiment::Consonance::IMPERFECT_CONSONANCE)
      end

      it "classifies compound perfect fifth as perfect consonance" do
        interval = HeadMusic::Analysis::DiatonicInterval.get("P12") # compound perfect fifth
        expect(tradition.consonance_classification(interval)).to eq(HeadMusic::Rudiment::Consonance::PERFECT_CONSONANCE)
      end
    end
  end

  describe "#name" do
    it "returns :modern" do
      expect(tradition.name).to eq(:modern)
    end
  end
end
