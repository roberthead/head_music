# frozen_string_literal: true

require 'spec_helper'

describe HeadMusic::Spelling::EnharmonicEquivalence do
  subject(:enharmonic_equivalence) { described_class.get(identifier) }

  describe 'constructor' do
    context 'when passed a pitch' do
      let(:identifier) { HeadMusic::Pitch.get('D♯5') }

      its(:spelling) { is_expected.to eq HeadMusic::Spelling.get('D♯') }
    end

    context 'when passed a pitch string' do
      let(:identifier) { 'D♯5' }

      its(:spelling) { is_expected.to eq HeadMusic::Spelling.get('D♯') }
    end

    context 'when passed a pitch class' do
      let(:identifier) { HeadMusic::PitchClass.get('D♯') }

      its(:spelling) { is_expected.to eq HeadMusic::Spelling.get('D♯') }
    end

    context 'when passed a spelling instance' do
      let(:identifier) { HeadMusic::Spelling.get('D♯') }

      its(:spelling) { is_expected.to eq HeadMusic::Spelling.get('D♯') }
    end

    context 'when passed a spelling string' do
      let(:identifier) { 'D♯' }

      its(:spelling) { is_expected.to eq HeadMusic::Spelling.get('D♯') }
    end
  end

  describe '#equivalent?' do
    let(:identifier) { HeadMusic::Spelling.get('D♯') }

    it { is_expected.to be_enharmonic_equivalent('E♭') }
    it { is_expected.to be_equivalent('E♭') }

    it { is_expected.not_to be_enharmonic_equivalent('D♯') }
    it { is_expected.not_to be_enharmonic_equivalent('D') }
    it { is_expected.not_to be_enharmonic_equivalent('E') }
    it { is_expected.not_to be_enharmonic_equivalent('E') }
  end
end
