require 'spec_helper'

describe HeadMusic::Style::Rulesets::ModernCantusFirmus do
  subject(:analysis) { HeadMusic::Style::Analysis.new(described_class, voice) }

  specify { expect(described_class::RULESET).to include HeadMusic::Style::Annotations::AlwaysMove }
  specify { expect(described_class::RULESET).to include HeadMusic::Style::Annotations::AtLeastEightNotes }
  specify { expect(described_class::RULESET).to include HeadMusic::Style::Annotations::ConsonantClimax }
  specify { expect(described_class::RULESET).to include HeadMusic::Style::Annotations::Diatonic }
  specify { expect(described_class::RULESET).to include HeadMusic::Style::Annotations::EndOnTonic }
  specify { expect(described_class::RULESET).to include HeadMusic::Style::Annotations::LimitOctaveLeaps }
  specify { expect(described_class::RULESET).to include HeadMusic::Style::Annotations::ModerateDirectionChanges }
  specify { expect(described_class::RULESET).to include HeadMusic::Style::Annotations::MostlyConjunct }
  specify { expect(described_class::RULESET).to include HeadMusic::Style::Annotations::NoRests }
  specify { expect(described_class::RULESET).to include HeadMusic::Style::Annotations::NotesSameLength }
  specify { expect(described_class::RULESET).to include HeadMusic::Style::Annotations::PrepareOctaveLeaps }
  specify { expect(described_class::RULESET).to include HeadMusic::Style::Annotations::SingableIntervals }
  specify { expect(described_class::RULESET).to include HeadMusic::Style::Annotations::SingableRange }
  specify { expect(described_class::RULESET).to include HeadMusic::Style::Annotations::SingleLargeLeaps }
  specify { expect(described_class::RULESET).to include HeadMusic::Style::Annotations::StartOnTonic }
  specify { expect(described_class::RULESET).to include HeadMusic::Style::Annotations::StepToFinalNote }
  specify { expect(described_class::RULESET).to include HeadMusic::Style::Annotations::UpToFourteenNotes }

  describe 'adherence' do
    context 'with Fux examples' do
      fux_cantus_firmus_examples.each do |example|
        context example.description do
          let(:voice) { example.composition.cantus_firmus }

          if example.expected_messages.length > 0
            it { is_expected.not_to be_adherent }

            example.expected_messages.each do |expected_message|
              its(:messages) { are_expected.to include(expected_message) }
            end
          else
            it { is_expected.to be_adherent }
          end
        end
      end
    end

    context 'with Clendinning examples' do
      theory_and_analysis_cantus_firmus_examples.each do |example|
        context example.description do
          let(:voice) { example.composition.cantus_firmus }

          if example.expected_messages.length > 0
            it { is_expected.not_to be_adherent }

            example.expected_messages.each do |expected_message|
              its(:messages) { are_expected.to include(expected_message) }
            end
          else
            it { is_expected.to be_adherent }
          end
        end
      end
    end

    context 'with Davis and Lybbert examples' do
      davis_and_lybbert_cantus_firmus_examples.each do |example|
        context example.description do
          let(:voice) { example.composition.cantus_firmus }

          if example.expected_messages.length > 0
            it { is_expected.not_to be_adherent }

            example.expected_messages.each do |expected_message|
              its(:messages) { are_expected.to include(expected_message) }
            end
          else
            it { is_expected.to be_adherent }
          end
        end
      end
    end

    context 'with Schoenberg examples' do
      schoenberg_cantus_firmus_examples.each do |example|
        context example.description do
          let(:voice) { example.composition.cantus_firmus }

          if example.expected_messages.length > 0
            it { is_expected.not_to be_adherent }

            example.expected_messages.each do |expected_message|
              its(:messages) { are_expected.to include(expected_message) }
            end
          else
            it { is_expected.to be_adherent }
          end
        end
      end
    end
  end
end
