# frozen_string_literal: true

require 'spec_helper'

FUX_FIRST_SPECIES_HARMONY_EXAMPLES = [
  {
    source: 'Fux chapter one figure 5',
    key: 'D dorian',
    cantus_firmus_pitches: %w[D4 F4 E4 D4 G4 F4 A4 G4 F4 E4 D4],
    counterpoint_pitches: %w[A A G A B C5 C5 B D5 C#5 D5],
  },
  {
    source: 'fux chapter one figure 6 (with errors)',
    key: 'D dorian',
    cantus_firmus_pitches: %w[D4 F4 E4 D4 G4 F4 A4 G4 F4 E4 D4],
    counterpoint_pitches: %w[G3 D A3 F3 E3 D3 F3 C D C# D],
    expected_message: 'Approach perfect consonances by contrary motion.',
  },
  {
    source: 'fux chapter one figure 6 (corrected)',
    key: 'D dorian',
    cantus_firmus_pitches: %w[D4 F4 E4 D4 G4 F4 A4 G4 F4 E4 D4],
    counterpoint_pitches: %w[D3 D3 A3 F3 E3 D3 F3 C D C# D],
  },
  {
    source: 'fux chapter one figure 11',
    key: 'E phrygian',
    cantus_firmus_pitches: %w[E C D C A3 A4 G E F E],
    counterpoint_pitches: %w[B C5 F G A C5 B E5 D5 E5],
  },
  {
    source: 'fux chapter one figure 12 (with melodic errors)',
    key: 'E phrygian',
    cantus_firmus_pitches: %w[E C D C A3 A4 G E F E],
    counterpoint_pitches: %w[E3 A3 D3 E3 F3 F3 B3 C4 D4 E4],
  },
  {
    source: 'fux chapter one figure 12 (corrected)',
    key: 'E phrygian',
    cantus_firmus_pitches: %w[E C D C A3 A4 G E F E],
    counterpoint_pitches:  %w[E3 A3 D3 E3 F3 F3 C4 C4 D4 E4],
  },
  {
    source: 'fux chapter one figure 13',
    key: 'F lydian',
    counterpoint_pitches: %w[F E C F F G A G C F E F],
    cantus_firmus_pitches: %w[F3 G3 A3 F3 D3 E3 F3 C4 A3 F3 G3 F3],
  },
  {
    source: 'fux chapter one figure 14',
    key: 'F ionian',
    cantus_firmus_pitches: %w[F3 G3 A3 F3 D3 E3 F3 C4 A3 F3 G3 F3],
    counterpoint_pitches:  %w[F3 E3 F3 A3 Bb3 G3 A3 E3 F3 D3 E3 F3],
    expected_message: 'Avoid crossing voices. Maintain the high-low relationship between voices.',
  },
  {
    source: 'fux chapter one figure 15 (with melodic errors)',
    key: 'G mixolydian',
    counterpoint_pitches:  %w[G4 E4 D4 G4 G4 G4 A4 B4 G4 E5 D5 G4 F#4 G4],
    cantus_firmus_pitches: %w[G3 C4 B3 G3 C4 E4 D4 G4 E4 C4 D4 B3 A3 G3],
  },
  {
    source: 'fux chapter one figure 15 (corrected)',
    key: 'G mixolydian',
    counterpoint_pitches:  %w[G4 E4 D4 G4 G4 G4 A4 B4 G4 C5 A4 G4 F#4 G4],
    cantus_firmus_pitches: %w[G3 C4 B3 G3 C4 E4 D4 G4 E4 C4 D4 B3 A3 G3],
  },
  {
    source: 'Fux chapter one figure 21',
    key: 'G ionian',
    cantus_firmus_pitches: %w[G3 C4 B3 G3 C4 E4 D4 G4 E4 C4 D4 B3 A3 G3],
    counterpoint_pitches:  %w[G3 A3 G3 E3 E3 C3 G3 B3 C4 A3 F#3 G3 F#3 G3],
    expected_message:
      'Avoid overlapping voices. Maintain the high-low relationship between voices even for adjacent notes.',
  },
  {
    source: 'Fux chapter one figure 22',
    key: 'A aeolian',
    counterpoint_pitches:  %w[A4 E4 G4 F4 E4 C5 A4 B4 B4 A4 G#4 A4],
    cantus_firmus_pitches: %w[A3 C4 B3 D4 C4 E4 F4 E4 D4 C4 B3 A3],
  },
  {
    source: 'Fux chapter one figure 23',
    key: 'A aeolian',
    cantus_firmus_pitches: %w[A3 C4 B3 D4 C4 E4 F4 E4 D4 C4 B3 A3],
    counterpoint_pitches:  %w[A3 A3 G3 F3 E3 E3 D3 C3 G3 A3 G#3 A3],
  },
].freeze

def fux_first_species_harmony_examples
  FUX_FIRST_SPECIES_HARMONY_EXAMPLES.map { |params| CompositionContext.from_params(params) }
end

describe HeadMusic::Style::Rulesets::FirstSpeciesHarmony do
  specify { expect(described_class::RULESET).to include HeadMusic::Style::Annotations::ApproachPerfectionContrarily }
  specify { expect(described_class::RULESET).to include HeadMusic::Style::Annotations::AvoidCrossingVoices }
  specify { expect(described_class::RULESET).to include HeadMusic::Style::Annotations::AvoidOverlappingVoices }
  specify { expect(described_class::RULESET).to include HeadMusic::Style::Annotations::ConsonantDownbeats }
  specify { expect(described_class::RULESET).to include HeadMusic::Style::Annotations::PreferContraryMotion }
  specify { expect(described_class::RULESET).to include HeadMusic::Style::Annotations::PreferImperfect }
  specify { expect(described_class::RULESET).to include HeadMusic::Style::Annotations::NoUnisonsInMiddle }
  specify { expect(described_class::RULESET).to include HeadMusic::Style::Annotations::OneToOne }
  specify { expect(described_class::RULESET).to include HeadMusic::Style::Annotations::AvoidCrossingVoices }

  context 'adherence' do
    subject(:analysis) { HeadMusic::Style::Analysis.new(described_class, voice) }

    context 'with Fux examples' do
      fux_first_species_harmony_examples.each do |example|
        context example.description do
          let(:voice) { example.composition.counterpoint_voice }

          if !example.expected_messages.empty?
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

          if !example.expected_messages.empty?
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

          if !example.expected_messages.empty?
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
