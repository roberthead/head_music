# frozen_string_literal: true

require 'spec_helper'

describe HeadMusic::Style::Rulesets::FuxCantusFirmus do
  specify { expect(described_class::RULESET).to include HeadMusic::Style::Annotations::AlwaysMove }
  specify { expect(described_class::RULESET).to include HeadMusic::Style::Annotations::AtLeastEightNotes }
  specify { expect(described_class::RULESET).to include HeadMusic::Style::Annotations::ConsonantClimax }
  specify { expect(described_class::RULESET).to include HeadMusic::Style::Annotations::Diatonic }
  specify { expect(described_class::RULESET).to include HeadMusic::Style::Annotations::EndOnTonic }
  specify { expect(described_class::RULESET).to include HeadMusic::Style::Annotations::FrequentDirectionChanges }
  specify { expect(described_class::RULESET).to include HeadMusic::Style::Annotations::LimitOctaveLeaps }
  specify { expect(described_class::RULESET).to include HeadMusic::Style::Annotations::MostlyConjunct }
  specify { expect(described_class::RULESET).to include HeadMusic::Style::Annotations::NoRests }
  specify { expect(described_class::RULESET).to include HeadMusic::Style::Annotations::NotesSameLength }
  specify { expect(described_class::RULESET).to include HeadMusic::Style::Annotations::RecoverLargeLeaps }
  specify { expect(described_class::RULESET).to include HeadMusic::Style::Annotations::SingableIntervals }
  specify { expect(described_class::RULESET).to include HeadMusic::Style::Annotations::SingableRange }
  specify { expect(described_class::RULESET).to include HeadMusic::Style::Annotations::StartOnTonic }
  specify { expect(described_class::RULESET).to include HeadMusic::Style::Annotations::StepDownToFinalNote }
  specify { expect(described_class::RULESET).to include HeadMusic::Style::Annotations::UpToFourteenNotes }

  describe 'adherence' do
    subject(:analysis) { HeadMusic::Style::Analysis.new(described_class, voice) }

    context 'with Fux examples' do
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

    context 'with Fux examples with errors introduced' do
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
end
