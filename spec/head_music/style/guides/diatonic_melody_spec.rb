require "spec_helper"

describe HeadMusic::Style::Guides::DiatonicMelody do
  let(:ruleset) { described_class::RULESET }

  describe "RULESET" do
    let(:included_guidelines) do
      [
        HeadMusic::Style::Guidelines::ConsonantClimax,
        HeadMusic::Style::Guidelines::Diatonic,
        HeadMusic::Style::Guidelines::LimitOctaveLeaps,
        HeadMusic::Style::Guidelines::ModerateDirectionChanges,
        HeadMusic::Style::Guidelines::MostlyConjunct,
        HeadMusic::Style::Guidelines::PrepareOctaveLeaps,
        HeadMusic::Style::Guidelines::SingableIntervals,
        HeadMusic::Style::Guidelines::SingableRange,
        HeadMusic::Style::Guidelines::SingleLargeLeaps
      ]
    end

    let(:omitted_guidelines) do
      [
        HeadMusic::Style::Guidelines::StartOnTonic,
        HeadMusic::Style::Guidelines::EndOnTonic,
        HeadMusic::Style::Guidelines::NoRests,
        HeadMusic::Style::Guidelines::NotesSameLength,
        HeadMusic::Style::Guidelines::StepToFinalNote
      ]
    end

    it "includes the free diatonic melody guidelines" do
      expect(ruleset).to include(*included_guidelines)
    end

    it "omits the cantus-firmus-specific guidelines" do
      expect(ruleset).not_to include(*omitted_guidelines)
    end

    describe "loosened note-count range of 5 to 24" do
      def configured_for(guideline_class)
        ruleset.find do |rule|
          rule.is_a?(HeadMusic::Style::Annotation::Configured) && rule.guideline_class == guideline_class
        end
      end

      it "sets a minimum of 5 notes" do
        expect(configured_for(HeadMusic::Style::Guidelines::MinimumNotes).options).to eq(minimum: 5)
      end

      it "sets a maximum of 24 notes" do
        expect(configured_for(HeadMusic::Style::Guidelines::MaximumNotes).options).to eq(maximum: 24)
      end
    end
  end
end
