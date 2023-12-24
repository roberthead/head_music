require "spec_helper"

describe HeadMusic::Style::Guides::ModernCantusFirmus do
  subject(:analysis) { HeadMusic::Style::Analysis.new(described_class, voice) }

  specify { expect(described_class::RULESET).to include HeadMusic::Style::Guidelines::AlwaysMove }
  specify { expect(described_class::RULESET).to include HeadMusic::Style::Guidelines::AtLeastEightNotes }
  specify { expect(described_class::RULESET).to include HeadMusic::Style::Guidelines::ConsonantClimax }
  specify { expect(described_class::RULESET).to include HeadMusic::Style::Guidelines::Diatonic }
  specify { expect(described_class::RULESET).to include HeadMusic::Style::Guidelines::EndOnTonic }
  specify { expect(described_class::RULESET).to include HeadMusic::Style::Guidelines::LimitOctaveLeaps }
  specify { expect(described_class::RULESET).to include HeadMusic::Style::Guidelines::ModerateDirectionChanges }
  specify { expect(described_class::RULESET).to include HeadMusic::Style::Guidelines::MostlyConjunct }
  specify { expect(described_class::RULESET).to include HeadMusic::Style::Guidelines::NoRests }
  specify { expect(described_class::RULESET).to include HeadMusic::Style::Guidelines::NotesSameLength }
  specify { expect(described_class::RULESET).to include HeadMusic::Style::Guidelines::PrepareOctaveLeaps }
  specify { expect(described_class::RULESET).to include HeadMusic::Style::Guidelines::SingableIntervals }
  specify { expect(described_class::RULESET).to include HeadMusic::Style::Guidelines::SingableRange }
  specify { expect(described_class::RULESET).to include HeadMusic::Style::Guidelines::SingleLargeLeaps }
  specify { expect(described_class::RULESET).to include HeadMusic::Style::Guidelines::StartOnTonic }
  specify { expect(described_class::RULESET).to include HeadMusic::Style::Guidelines::StepToFinalNote }
  specify { expect(described_class::RULESET).to include HeadMusic::Style::Guidelines::UpToFourteenNotes }

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

  context "with Clendinning examples" do
    clendinning_cantus_firmus_examples.each do |example|
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

  context "with Davis and Lybbert examples" do
    davis_and_lybbert_cantus_firmus_examples.each do |example|
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

  context "with Schoenberg examples" do
    schoenberg_cantus_firmus_examples.each do |example|
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
