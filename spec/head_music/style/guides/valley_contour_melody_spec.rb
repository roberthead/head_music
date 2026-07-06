require "spec_helper"

describe HeadMusic::Style::Guides::ValleyContourMelody do
  describe "RULESET" do
    let(:ruleset) { described_class::RULESET }

    it "includes all the diatonic melody guidelines" do
      expect(ruleset).to include(*HeadMusic::Style::Guides::DiatonicMelody::RULESET)
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

    context "with a melody bottoming out on the last note" do
      let(:melody) { "GFED|C4|" }

      it "objects to the contour" do
        expect(analysis.messages).to include(contour_message)
      end
    end
  end
end
