# frozen_string_literal: true

require 'spec_helper'

describe HeadMusic::Style::Rulesets::FirstSpeciesMelody do
  specify { expect(described_class::RULESET).to include HeadMusic::Style::Annotations::ConsonantClimax }
  specify { expect(described_class::RULESET).to include HeadMusic::Style::Annotations::Diatonic }
  specify { expect(described_class::RULESET).to include HeadMusic::Style::Annotations::EndOnTonic }
  specify { expect(described_class::RULESET).to include HeadMusic::Style::Annotations::FrequentDirectionChanges }
  specify { expect(described_class::RULESET).to include HeadMusic::Style::Annotations::LimitOctaveLeaps }
  specify { expect(described_class::RULESET).to include HeadMusic::Style::Annotations::MostlyConjunct }
  specify { expect(described_class::RULESET).to include HeadMusic::Style::Annotations::NoRests }
  specify { expect(described_class::RULESET).to include HeadMusic::Style::Annotations::NotesSameLength }
  specify { expect(described_class::RULESET).to include HeadMusic::Style::Annotations::PrepareOctaveLeaps }
  specify { expect(described_class::RULESET).to include HeadMusic::Style::Annotations::SingableIntervals }
  specify { expect(described_class::RULESET).to include HeadMusic::Style::Annotations::SingableRange }
  specify { expect(described_class::RULESET).to include HeadMusic::Style::Annotations::StartOnPerfectConsonance }
  specify { expect(described_class::RULESET).to include HeadMusic::Style::Annotations::StepOutOfUnison }
  specify { expect(described_class::RULESET).to include HeadMusic::Style::Annotations::StepUpToFinalNote }

  context 'adherence' do
    subject(:analysis) { HeadMusic::Style::Analysis.new(described_class, voice) }

    context 'with Fux examples' do
      fux_first_species_examples.each do |example|
        context example.description do
          let(:voice) { example.composition.counterpoint_voice }

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

    context 'with Clendinning examples' do
      clendinning_first_species_examples.each do |example|
        context example.description do
          let(:voice) { example.composition.counterpoint_voice }

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

    context 'with Davis and Lybbert examples' do
      davis_and_lybbert_first_species_examples.each do |example|
        context example.description do
          let(:voice) { example.composition.counterpoint_voice }

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
