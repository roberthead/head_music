require 'spec_helper'

describe HeadMusic::Style::Rulesets::FirstSpeciesHarmony do
  let(:composition) { Composition.new(key_signature: 'D dorian') }
  let(:cantus_firmus_pitches) { %w[D4 F4 E4 D4 G4 F4 A4 G4 F4 E4 D4] }
  let!(:cantus_firmus) do
    composition.add_voice(role: :cantus_firmus).tap do |cantus_firmus|
      cantus_firmus_pitches.each.with_index(1) do |pitch, bar|
        cantus_firmus.place("#{bar}:1", :whole, pitch)
      end
    end
  end
  subject(:analysis) { HeadMusic::Style::Analysis.new(described_class, counterpoint) }

  specify { expect(described_class::RULESET).to include HeadMusic::Style::Annotations::ApproachPerfectionContrarily }
  specify { expect(described_class::RULESET).to include HeadMusic::Style::Annotations::AvoidCrossingVoices }
  specify { expect(described_class::RULESET).to include HeadMusic::Style::Annotations::AvoidOverlappingVoices }
  specify { expect(described_class::RULESET).to include HeadMusic::Style::Annotations::ConsonantDownbeats }
  specify { expect(described_class::RULESET).to include HeadMusic::Style::Annotations::PreferContraryMotion }
  specify { expect(described_class::RULESET).to include HeadMusic::Style::Annotations::PreferImperfect }
  specify { expect(described_class::RULESET).to include HeadMusic::Style::Annotations::NoUnisonsInMiddle }
  specify { expect(described_class::RULESET).to include HeadMusic::Style::Annotations::OneToOne }
  specify { expect(described_class::RULESET).to include HeadMusic::Style::Annotations::AvoidCrossingVoices }

  context 'with two voices' do
    let(:composition) { Composition.new(key_signature: key) }
    let!(:cantus_firmus) do
      composition.add_voice(role: :cantus_firmus).tap do |voice|
        cantus_firmus_pitches.each.with_index(1) do |pitch, bar|
          duration = bar == counterpoint_pitches.length ? 'double whole' : 'whole'
          voice.place("#{bar}:1", duration, pitch)
        end
      end
    end
    let(:counterpoint) do
      composition.add_voice(role: :counterpoint).tap do |voice|
        counterpoint_pitches.each.with_index(1) do |pitch, bar|
          duration = bar == counterpoint_pitches.length ? 'double whole' : 'whole'
          voice.place("#{bar}:1", duration, pitch)
        end
      end
    end

    subject(:analysis) { HeadMusic::Style::Analysis.new(described_class, counterpoint) }

    context 'fux chapter one figure 5' do
      let(:key) { 'D dorian' }
      let(:cantus_firmus_pitches) { %w[D4 F4 E4 D4 G4 F4 A4 G4 F4 E4 D4] }
      let(:counterpoint_pitches) { %w[A A G A B C5 C5 B D5 C#5 D5] }

      it { is_expected.to be_adherent }
      its(:annotation_messages) { are_expected.to eq [] }
    end

    context 'fux chapter one figure 6 (with errors)' do
      let(:key) { 'D dorian' }
      let(:cantus_firmus_pitches) { %w[D4 F4 E4 D4 G4 F4 A4 G4 F4 E4 D4] }
      let(:counterpoint_pitches) { %w[G3 D A3 F3 E3 D3 F3 C D C# D] }

      its(:fitness) { is_expected.to be < 1 }
      its(:annotation_messages) { are_expected.to include 'Approach perfect consonances by contrary motion.' }
    end

    context 'fux chapter one figure 6 (corrected)' do
      let(:key) { 'D dorian' }
      let(:cantus_firmus_pitches) { %w[D4 F4 E4 D4 G4 F4 A4 G4 F4 E4 D4] }
      let(:counterpoint_pitches) { %w[D3 D3 A3 F3 E3 D3 F3 C D C# D] }

      it { is_expected.to be_adherent }
      its(:annotation_messages) { are_expected.to eq [] }
    end

    context 'fux chapter one figure 11' do
      let(:key) { 'E phrygian' }
      let(:counterpoint_pitches) { %w[B C5 F G A C5 B E5 D5 E5] }
      let(:cantus_firmus_pitches) { %w[E C D C A3 A4 G E F E] }

      it { is_expected.to be_adherent }
      its(:annotation_messages) { are_expected.to eq [] }
    end

    context 'fux chapter one figure 12 (with errors)' do
      let(:key) { 'E phrygian' }
      let(:cantus_firmus_pitches) { %w[E C D C A3 A4 G E F E] }
      let(:counterpoint_pitches) { %w[E3 A3 D3 E3 F3 F3 B3 C4 D4 E4] }

      it { is_expected.to be_adherent }
      its(:annotation_messages) { are_expected.to eq [] }
    end

    context 'fux chapter one figure 12 (corrected)' do
      let(:key) { 'E phrygian' }
      let(:cantus_firmus_pitches) { %w[E C  D  C  A3 A4 G  E  F  E] }
      let(:counterpoint_pitches) { %w[E3 A3 D3 E3 F3 F3 C4 C4 D4 E4] }

      it { is_expected.to be_adherent }
      its(:annotation_messages) { are_expected.to eq [] }
    end

    context 'fux chapter one figure 13' do
      let(:key) { 'F lydian' }
      let(:counterpoint_pitches) { %w[F E C F F G A G C F E F] }
      let(:cantus_firmus_pitches) { %w[F3 G3 A3 F3 D3 E3 F3 C4 A3 F3 G3 F3] }

      it { is_expected.to be_adherent }
      its(:annotation_messages) { are_expected.to eq [] }
    end

    context 'fux chapter one figure 14' do
      let(:key) { 'F ionian' }
      let(:cantus_firmus_pitches) { %w[F3 G3 A3 F3 D3 E3 F3 C4 A3 F3 G3 F3] }
      let(:counterpoint_pitches) { %w[F3 E3 F3 A3 Bb3 G3 A3 E3 F3 D3 E3 F3] }

      its(:fitness) { is_expected.to be < 1 }
      its(:annotation_messages) { are_expected.to include 'Avoid crossing voices.' }
    end

    context 'fux chapter one figure 15 (with errors)' do
      let(:key) { 'G mixolydian' }
      let(:counterpoint_pitches) {  %w[G4 E4 D4 G4 G4 G4 A4 B4 G4 E5 D5 G4 F#4 G4] }
      let(:cantus_firmus_pitches) { %w[G3 C4 B3 G3 C4 E4 D4 G4 E4 C4 D4 B3 A3  G3] }

      it { is_expected.to be_adherent }
      its(:annotation_messages) { are_expected.to eq [] }
    end

    context 'fux chapter one figure 15 (corrected)' do
      let(:key) { 'G mixolydian' }
      let(:counterpoint_pitches) {  %w[G4 E4 D4 G4 G4 G4 A4 B4 G4 C5 A4 G4 F#4 G4] }
      let(:cantus_firmus_pitches) { %w[G3 C4 B3 G3 C4 E4 D4 G4 E4 C4 D4 B3 A3  G3] }

      it { is_expected.to be_adherent }
      its(:annotation_messages) { are_expected.to eq [] }
    end

    context 'fux chapter one figure 21' do
      let(:key) { 'G ionian' }
      let(:cantus_firmus_pitches) { %w[G3 C4 B3 G3 C4 E4 D4 G4 E4 C4 D4  B3 A3  G3] }
      let(:counterpoint_pitches) {  %w[G3 A3 G3 E3 E3 C3 G3 B3 C4 A3 F#3 G3 F#3 G3] }

      its(:fitness) { is_expected.to be < 1 }
      its(:annotation_messages) { are_expected.to include 'Avoid overlapping voices.' }
    end

    context 'fux chapter one figure 22' do
      let(:key) { 'A aeolian' }
      let(:counterpoint_pitches) {  %w[A4 E4 G4 F4 E4 C5 A4 B4 B4 A4 G#4 A4] }
      let(:cantus_firmus_pitches) { %w[A3 C4 B3 D4 C4 E4 F4 E4 D4 C4 B3  A3] }

      it { is_expected.to be_adherent }
      its(:annotation_messages) { are_expected.to eq [] }
    end

    context 'fux chapter one figure 23' do
      let(:key) { 'A aeolian' }
      let(:cantus_firmus_pitches) { %w[A3 C4 B3 D4 C4 E4 F4 E4 D4 C4 B3  A3] }
      let(:counterpoint_pitches) {  %w[A3 A3 G3 F3 E3 E3 D3 C3 G3 A3 G#3 A3] }

      it { is_expected.to be_adherent }
      its(:annotation_messages) { are_expected.to eq [] }
    end
  end
end
