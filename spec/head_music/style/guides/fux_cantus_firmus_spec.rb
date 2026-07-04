require "spec_helper"

describe HeadMusic::Style::Guides::FuxCantusFirmus do
  subject(:analysis) { HeadMusic::Style::Analysis.new(described_class, voice) }

  let(:large_leaps_options) do
    {
      message: "Recover large leaps by step in the opposite direction.",
      minimum: :perfect_fourth,
      descending: {minimum: :perfect_fourth, forbidden: :minor_sixth},
      recovery: %i[consonant_triad opposite_step]
    }
  end

  specify { expect(described_class::RULESET).to include HeadMusic::Style::Guidelines::AlwaysMove }
  specify { expect(described_class::RULESET).to include configured(HeadMusic::Style::Guidelines::MinimumNotes, minimum: 8) }
  specify { expect(described_class::RULESET).to include HeadMusic::Style::Guidelines::ConsonantClimax }
  specify { expect(described_class::RULESET).to include HeadMusic::Style::Guidelines::Diatonic }
  specify { expect(described_class::RULESET).to include HeadMusic::Style::Guidelines::EndOnTonic }
  specify { expect(described_class::RULESET).to include HeadMusic::Style::Guidelines::FrequentDirectionChanges }
  specify { expect(described_class::RULESET).to include HeadMusic::Style::Guidelines::LimitOctaveLeaps }
  specify { expect(described_class::RULESET).to include HeadMusic::Style::Guidelines::MostlyConjunct }
  specify { expect(described_class::RULESET).to include HeadMusic::Style::Guidelines::NoRests }
  specify { expect(described_class::RULESET).to include HeadMusic::Style::Guidelines::NotesSameLength }

  specify { expect(described_class::RULESET).to include configured(HeadMusic::Style::Guidelines::LargeLeaps, **large_leaps_options) }

  specify { expect(described_class::RULESET).to include HeadMusic::Style::Guidelines::SingableIntervals }
  specify { expect(described_class::RULESET).to include HeadMusic::Style::Guidelines::SingableRange }
  specify { expect(described_class::RULESET).to include HeadMusic::Style::Guidelines::StartOnTonic }
  specify { expect(described_class::RULESET).to include HeadMusic::Style::Guidelines::StepDownToFinalNote }
  specify { expect(described_class::RULESET).to include configured(HeadMusic::Style::Guidelines::MaximumNotes, maximum: 14) }

  context "with Fux examples" do
    fux_cantus_firmus_examples.each do |example|
      context example.description do
        let(:voice) { example.composition.cantus_firmus_voice }

        if example.expected_messages.any?
          it { is_expected.not_to be_adherent }

          example.expected_messages.each do |expected_message|
            its(:annotation_messages) { are_expected.to include(expected_message) }
          end
        else
          it { is_expected.to be_adherent }
        end
      end
    end
  end

  context "with Fux examples with errors introduced" do
    fux_cantus_firmus_examples_with_errors.each do |example|
      context example.description do
        let(:voice) { example.composition.cantus_firmus_voice }

        if example.expected_messages.any?
          it { is_expected.not_to be_adherent }

          example.expected_messages.each do |expected_message|
            its(:annotation_messages) { are_expected.to include(expected_message) }
          end
        else
          it { is_expected.to be_adherent }
        end
      end
    end
  end
end
