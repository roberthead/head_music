require "spec_helper"

describe HeadMusic::Style::MedievalTradition do
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

      it "classifies perfect fourth as perfect consonance (key difference from Renaissance)" do
        interval = HeadMusic::Analysis::DiatonicInterval.get("P4")
        expect(tradition.consonance_classification(interval)).to eq(HeadMusic::Rudiment::Consonance::PERFECT_CONSONANCE)
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

    context "with dissonances" do
      it "classifies major second as dissonance" do
        interval = HeadMusic::Analysis::DiatonicInterval.get("M2")
        expect(tradition.consonance_classification(interval)).to eq(HeadMusic::Rudiment::Consonance::DISSONANCE)
      end

      it "classifies minor second as dissonance" do
        interval = HeadMusic::Analysis::DiatonicInterval.get("m2")
        expect(tradition.consonance_classification(interval)).to eq(HeadMusic::Rudiment::Consonance::DISSONANCE)
      end

      it "classifies major seventh as dissonance" do
        interval = HeadMusic::Analysis::DiatonicInterval.get("M7")
        expect(tradition.consonance_classification(interval)).to eq(HeadMusic::Rudiment::Consonance::DISSONANCE)
      end

      it "classifies minor seventh as dissonance" do
        interval = HeadMusic::Analysis::DiatonicInterval.get("m7")
        expect(tradition.consonance_classification(interval)).to eq(HeadMusic::Rudiment::Consonance::DISSONANCE)
      end

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
    end

    context "with compound intervals" do
      it "classifies compound intervals based on their simple form" do
        interval = HeadMusic::Analysis::DiatonicInterval.get("M10") # compound major third
        expect(tradition.consonance_classification(interval)).to eq(HeadMusic::Rudiment::Consonance::IMPERFECT_CONSONANCE)
      end

      it "classifies compound perfect fourth as perfect consonance" do
        interval = HeadMusic::Analysis::DiatonicInterval.get("P11") # compound perfect fourth
        expect(tradition.consonance_classification(interval)).to eq(HeadMusic::Rudiment::Consonance::PERFECT_CONSONANCE)
      end
    end
  end

  describe "#name" do
    it "returns :medieval" do
      expect(tradition.name).to eq(:medieval)
    end
  end

  describe "comparison with other traditions" do
    let(:perfect_fourth) { HeadMusic::Analysis::DiatonicInterval.get("P4") }

    it "treats perfect fourth as consonant like modern tradition" do
      medieval_classification = tradition.consonance_classification(perfect_fourth)
      modern_classification = HeadMusic::Style::ModernTradition.new.consonance_classification(perfect_fourth)

      expect(medieval_classification).to eq(HeadMusic::Rudiment::Consonance::PERFECT_CONSONANCE)
      expect(modern_classification).to eq(HeadMusic::Rudiment::Consonance::PERFECT_CONSONANCE)
    end

    it "treats perfect fourth differently from Renaissance tradition" do
      medieval_classification = tradition.consonance_classification(perfect_fourth)
      renaissance_classification = HeadMusic::Style::RenaissanceTradition.new.consonance_classification(perfect_fourth)

      expect(medieval_classification).to eq(HeadMusic::Rudiment::Consonance::PERFECT_CONSONANCE)
      expect(renaissance_classification).to eq(HeadMusic::Rudiment::Consonance::DISSONANCE)
    end
  end
end
