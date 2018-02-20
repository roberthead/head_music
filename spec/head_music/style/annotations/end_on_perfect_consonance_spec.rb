# frozen_string_literal: true

require 'spec_helper'

describe HeadMusic::Style::Annotations::EndOnPerfectConsonance do
  let(:composition) { Composition.new(key_signature: 'C major') }
  let!(:cantus_firmus) do
    composition.add_voice(role: 'cantus firmus').tap do |voice|
      voice.place('1:1', :whole, 'C4')
      voice.place('2:1', :whole, 'D4')
      voice.place('3:1', :whole, 'E4')
      voice.place('4:1', :whole, 'D4')
      voice.place('5:1', :whole, 'C4')
    end
  end
  let(:counterpoint_pitches) { nil }
  let(:voice) do
    composition.add_voice(role: 'counterpoint').tap do |voice|
      [counterpoint_pitches].flatten.each.with_index(1) do |pitch, bar|
        voice.place("#{bar}:1", :whole, pitch)
      end
    end
  end

  subject { described_class.new(voice) }

  context 'when there are no notes' do
    let(:counterpoint_pitches) { [] }

    it { is_expected.to be_adherent }
  end

  context 'when the last note is a perfect unison' do
    let(:counterpoint_pitches) { %w[G4 F4 C4 B3 C4] }

    it { is_expected.to be_adherent }
  end

  context 'when the last note is an augmented unison' do
    let(:counterpoint_pitches) { %w[G4 F4 C4 B3 C#4] }

    its(:fitness) { is_expected.to be <= HeadMusic::PENALTY_FACTOR }
  end

  context 'when the last note is a perfect fifth above' do
    let(:counterpoint_pitches) { %w[G4 F4 G4 A4 G4] }

    it { is_expected.to be_adherent }
  end

  context 'when the last note is a perfect octave above' do
    let(:counterpoint_pitches) { %w[G4 A4 G4 B4 C5] }

    it { is_expected.to be_adherent }
  end

  context 'when the last note is a perfect fifth below' do
    let(:counterpoint_pitches) { %w[C4 B3 A3 G3 F3] }

    its(:fitness) { is_expected.to be < 1 }
  end

  context 'when the last note is an imperfect consonance' do
    let(:counterpoint_pitches) { %w[C5 B4 G4 F4 E4] }

    its(:fitness) { is_expected.to be < 1 }
  end

  context 'when the last note is a dissonance' do
    let(:counterpoint_pitches) { %w[C5 B4 G4 F4 D4] }

    its(:fitness) { is_expected.to be <= HeadMusic::PENALTY_FACTOR }
  end
end
