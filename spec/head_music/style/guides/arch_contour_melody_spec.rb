require "spec_helper"

describe HeadMusic::Style::Guides::ArchContourMelody do
  describe "RULESET" do
    let(:ruleset) { described_class::RULESET }

    it "includes all the diatonic melody guidelines" do
      expect(ruleset).to include(*HeadMusic::Style::Guides::DiatonicMelody::RULESET)
    end

    it "adds the arch contour guideline" do
      expect(ruleset).to include(
        configured(HeadMusic::Style::Guidelines::Contoured, contour: :arch)
      )
    end
  end

  describe "analysis" do
    subject(:analysis) { HeadMusic::Style::Analysis.new(described_class, voice) }

    let(:composition) { HeadMusic::Notation::ABC.parse(abc) }
    let(:voice) { composition.voices.first }
    let(:contour_message) { "Write a melody with the arch contour." }

    let(:abc) do
      <<~ABC
        X:1
        M:4/4
        L:1/4
        K:C
        #{melody}
      ABC
    end

    context "with an arching melody" do
      let(:melody) { "CDEG|EDC2|" }

      it "does not object to the contour" do
        expect(analysis.messages).not_to include(contour_message)
      end
    end

    context "with a melody climaxing on the last note" do
      let(:melody) { "CDEF|G4|" }

      it "objects to the contour" do
        expect(analysis.messages).to include(contour_message)
      end
    end
  end
end
