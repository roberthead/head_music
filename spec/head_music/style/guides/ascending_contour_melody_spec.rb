require "spec_helper"

describe HeadMusic::Style::Guides::AscendingContourMelody do
  describe "RULESET" do
    let(:ruleset) { described_class::RULESET }
    let(:peer_weight) { HeadMusic::GOLDEN_RATIO_INVERSE**2 / 10 }

    it "carries every diatonic melody guideline" do
      diatonic_classes = HeadMusic::Style::Guides::DiatonicMelody::RULESET.map do |entry|
        entry.respond_to?(:guideline_class) ? entry.guideline_class : entry
      end
      expect(ruleset.map(&:guideline_class)).to include(*diatonic_classes)
    end

    it "gates on at least one moving melodic interval" do
      expect(ruleset).to include(
        configured(HeadMusic::Style::Guidelines::MinimumMelodicIntervals, minimum: 1)
      )
    end

    it "weights each rubric peer evenly within the phi^-2 budget" do
      peers = ruleset.reject(&:default_gate?).reject do |entry|
        entry.guideline_class == HeadMusic::Style::Guidelines::Contoured
      end
      expect(peers.length).to eq 10
      expect(peers).to all(have_attributes(options: hash_including(weight: peer_weight)))
    end

    it "adds the ascending contour guideline" do
      expect(ruleset).to include(
        configured(HeadMusic::Style::Guidelines::Contoured, contour: :ascending)
      )
    end
  end

  describe "analysis" do
    subject(:analysis) { HeadMusic::Style::Analysis.new(described_class, voice) }

    let(:composition) { HeadMusic::Notation::ABC.parse(abc) }
    let(:voice) { composition.voices.first }
    let(:contour_message) { "Write a melody with the ascending contour." }

    let(:abc) do
      <<~ABC
        X:1
        M:4/4
        L:1/4
        K:C
        #{melody}
      ABC
    end

    context "with an undulating-yet-ascending melody" do
      let(:melody) { "CDED|EFEF|G4|" }

      it "does not object to the contour" do
        expect(analysis.messages).not_to include(contour_message)
      end

      it "does not object to the direction changes either" do
        expect(analysis).to be_adherent
      end

      it "grades a perfect submission at one" do
        expect(analysis.fitness).to eq 1.0
      end
    end

    context "with an arching melody" do
      let(:melody) { "CDEG|EDC2|" }

      it "objects to the contour" do
        expect(analysis.messages).to include(contour_message)
      end
    end
  end
end
