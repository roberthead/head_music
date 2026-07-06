require "spec_helper"

describe HeadMusic::Style::Guides::ValleyContourMelody do
  describe "RULESET" do
    let(:ruleset) { described_class::RULESET }
    let(:peer_weight) { HeadMusic::GOLDEN_RATIO_INVERSE**2 / 10 }

    it "carries every diatonic melody guideline" do
      diatonic_classes = HeadMusic::Style::Guides::DiatonicMelody::RULESET.map do |entry|
        entry.respond_to?(:guideline_class) ? entry.guideline_class : entry
      end
      expect(ruleset.map(&:guideline_class)).to include(*diatonic_classes)
    end

    it "gates on at least two moving melodic intervals" do
      expect(ruleset).to include(
        configured(HeadMusic::Style::Guidelines::MinimumMelodicIntervals, minimum: 2)
      )
    end

    it "weights each rubric peer evenly within the phi^-2 budget" do
      peers = ruleset.reject(&:default_gate?).reject do |entry|
        entry.guideline_class == HeadMusic::Style::Guidelines::Contoured
      end
      expect(peers.length).to eq 10
      expect(peers).to all(have_attributes(options: hash_including(weight: peer_weight)))
    end

    it "adds the valley contour guideline" do
      expect(ruleset).to include(
        configured(HeadMusic::Style::Guidelines::Contoured, contour: :valley)
      )
    end
  end

  describe "analysis" do
    subject(:analysis) { HeadMusic::Style::Analysis.new(described_class, voice) }

    let(:composition) { HeadMusic::Notation::ABC.parse(abc) }
    let(:voice) { composition.voices.first }
    let(:contour_message) { "Write a melody with the valley contour." }

    let(:abc) do
      <<~ABC
        X:1
        M:4/4
        L:1/4
        K:C
        #{melody}
      ABC
    end

    context "with an interior nadir" do
      let(:melody) { "GFEC|DEFG|" }

      it "does not object to the contour" do
        expect(analysis.messages).not_to include(contour_message)
      end
    end

    context "with an interior nadir and a single peak" do
      let(:melody) { "GFED|CDEF|" }

      it "grades a perfect submission at one" do
        expect(analysis.fitness).to eq 1.0
      end

      it "is adherent" do
        expect(analysis).to be_adherent
      end
    end

    context "with a melody bottoming out on the last note" do
      let(:melody) { "GFED|C4|" }

      it "objects to the contour" do
        expect(analysis.messages).to include(contour_message)
      end
    end
  end
end
