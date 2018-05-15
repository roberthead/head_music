# frozen_string_literal: true

require 'spec_helper'

describe HeadMusic::Pitch::EnharmonicEquivalence do
  subject(:enharmonic_equivalence) { described_class.get(pitch) }

  describe 'constructor' do
    context 'when passed a pitch' do
      let(:pitch) { HeadMusic::Pitch.get('D5') }

      its(:pitch_class) { is_expected.to eq HeadMusic::PitchClass.get('D') }
      its(:pitch) { is_expected.to eq HeadMusic::Pitch.get('D5') }
    end

    context 'when passed a pitch string' do
      let(:pitch) { 'D5' }

      its(:pitch_class) { is_expected.to eq HeadMusic::PitchClass.get('D') }
      its(:pitch) { is_expected.to eq HeadMusic::Pitch.get('D5') }
    end

    context 'when passed a pitch class' do
      let(:pitch) { HeadMusic::PitchClass.get('D') }

      its(:pitch_class) { is_expected.to eq HeadMusic::PitchClass.get('D') }
      its(:pitch) { is_expected.to eq HeadMusic::Pitch.get('D4') }
    end

    context 'when passed a pitch class string' do
      let(:pitch) { 'D' }

      its(:pitch_class) { is_expected.to eq HeadMusic::PitchClass.get('D') }
      its(:pitch) { is_expected.to eq HeadMusic::Pitch.get('D4') }
    end
  end

  describe '#equivalent?' do
    let(:pitch) { HeadMusic::Pitch.get('D#3') }

    it { is_expected.to be_enharmonic_equivalent('E♭3') }
    it { is_expected.to be_equivalent('E♭3') }

    it { is_expected.not_to be_enharmonic_equivalent('E♭4') }
    it { is_expected.not_to be_enharmonic_equivalent('E3') }
    it { is_expected.not_to be_enharmonic_equivalent('E♯3') }
  end
end
