require "spec_helper"

describe HeadMusic::Style::Guides::StaticContourMelody do
  describe "RULESET" do
    let(:ruleset) { described_class::RULESET }
    let(:peer_weight) { HeadMusic::GOLDEN_RATIO_INVERSE**2 / 10 }

    it "carries every diatonic melody guideline" do
      diatonic_classes = HeadMusic::Style::Guides::DiatonicMelody::RULESET.map do |entry|
        entry.respond_to?(:guideline_class) ? entry.guideline_class : entry
      end
      expect(ruleset.map(&:guideline_class)).to include(*diatonic_classes)
    end

    it "passes the note-count gate through unchanged" do
      expect(ruleset).to include(
        configured(HeadMusic::Style::Guidelines::MinimumNotes, minimum: 5)
      )
    end

    it "omits the motion gate so a repeated-note line can score" do
      expect(ruleset.map(&:guideline_class))
        .not_to include(HeadMusic::Style::Guidelines::MinimumMelodicIntervals)
    end

    it "weights each rubric peer evenly within the phi^-2 budget" do
      peers = ruleset.reject(&:default_gate?).reject do |entry|
        entry.guideline_class == HeadMusic::Style::Guidelines::Contoured
      end
      expect(peers.length).to eq 10
      expect(peers).to all(have_attributes(options: hash_including(weight: peer_weight)))
    end

    it "adds the static contour guideline" do
      expect(ruleset).to include(
        configured(HeadMusic::Style::Guidelines::Contoured, contour: :static)
      )
    end
  end

  describe "analysis" do
    subject(:analysis) { HeadMusic::Style::Analysis.new(described_class, voice) }

    let(:composition) { HeadMusic::Notation::ABC.parse(abc) }
    let(:voice) { composition.voices.first }
    let(:contour_message) { "Write a melody with the static contour." }

    let(:abc) do
      <<~ABC
        X:1
        M:4/4
        L:1/4
        K:C
        #{melody}
      ABC
    end

    context "with a narrow-range melody with neutral endpoints" do
      let(:melody) { "EDEF|EFED|E4|" }

      it "does not object to the contour" do
        expect(analysis.messages).not_to include(contour_message)
      end

      it "grades a perfect submission at one" do
        expect(analysis.fitness).to eq 1.0
      end
    end

    context "with an all-repeated-note line" do
      let(:melody) { "E4|E4|E4|E4|E4|" }

      it "does not object to the contour" do
        expect(analysis.messages).not_to include(contour_message)
      end

      it "does not gate the grade to zero" do
        expect(analysis.fitness).to be > 0.9
      end

      it "passes every gate" do
        gates = analysis.annotations.select(&:gate?)
        expect(gates.map(&:fitness)).to all(eq(1.0))
      end
    end

    context "with a melody spanning a fifth" do
      let(:melody) { "CDEF|G4|" }

      it "objects to the contour" do
        expect(analysis.messages).to include(contour_message)
      end
    end
  end
end
