# frozen_string_literal: true

require 'spec_helper'

describe HeadMusic::Spelling do
  describe '.get' do
    context 'when given an instance' do
      let(:instance) { described_class.get('A♯5') }

      it 'returns that instance' do
        expect(described_class.get(instance)).to be instance
      end
    end

    context "for 'C'" do
      subject(:spelling) { described_class.get('C') }

      its(:letter_name) { is_expected.to eq 'C' }
      its(:sign) { is_expected.to be_nil }
      its(:pitch_class) { is_expected.to eq 0 }
      it { is_expected.to eq 'C' }
    end

    context "for 'F♯'" do
      subject(:spelling) { described_class.get('F♯') }

      its(:letter_name) { is_expected.to eq 'F' }
      its(:sign) { is_expected.to eq '♯' }
      its(:pitch_class) { is_expected.to eq 6 }
      it { is_expected.to eq 'F♯' }
    end

    context "for 'Bb'" do
      subject(:spelling) { described_class.get('Bb') }

      its(:pitch_class) { is_expected.to eq 10 }
      it { is_expected.to eq 'Bb' }
    end

    context "for 'Cb'" do
      subject(:spelling) { described_class.get('Cb') }

      its(:pitch_class) { is_expected.to eq 11 }
      it { is_expected.to eq 'Cb' }
    end

    context "for 'B♯'" do
      subject(:spelling) { described_class.get('B♯') }

      its(:letter_name) { is_expected.to eq 'B' }
      its(:sign) { is_expected.to eq '♯' }
      its(:pitch_class) { is_expected.to eq 0 }
      it { is_expected.to eq 'B♯' }
    end

    context "for 'bb'" do
      subject(:spelling) { described_class.get('bb') }

      its(:letter_name) { is_expected.to eq 'B' }
      its(:sign) { is_expected.to eq 'b' }
      its(:pitch_class) { is_expected.to eq 10 }
      it { is_expected.to eq 'Bb' }
    end

    context 'given a pitch class' do
      subject(:spelling) { described_class.get(HeadMusic::PitchClass.get(3)) }

      its(:pitch_class) { is_expected.to eq 3 }
      it { is_expected.to eq 'D♯' }
    end

    context 'given a pitch class number' do
      subject(:spelling) { described_class.get(1) }

      its(:pitch_class) { is_expected.to eq 1 }
      it { is_expected.to eq 'C♯' }
    end

    context 'given the pitch class number for F♯/Gb' do
      subject(:spelling) { described_class.get(6) }

      its(:pitch_class) { is_expected.to eq 6 }
      it { is_expected.to eq 'F♯' }
    end
  end

  describe '#scale' do
    context 'without an argument' do
      subject(:scale) { described_class.get('D').scale }

      its(:spellings) { are_expected.to eq %w[D E F♯ G A B C♯ D] }
    end

    context 'passed a scale type' do
      subject(:scale) { described_class.get('E').scale(:minor) }

      its(:spellings) { are_expected.to eq %w[E F♯ G A B C D E] }
    end
  end

  describe '#letter_name_cycle' do
    subject(:spelling) { described_class.get('D') }

    its(:letter_name_cycle) { is_expected.to eq %w[D E F G A B C] }
  end

  describe '#enharmonic?' do
    specify { expect(described_class.get('G♯')).to be_enharmonic(described_class.get('Ab')) }
    specify { expect(described_class.get('G♯')).not_to be_enharmonic(described_class.get('G')) }
    specify { expect(described_class.get('G♯')).not_to be_enharmonic(described_class.get('A')) }

    specify { expect(described_class.get('C')).to be_enharmonic(described_class.get('B♯')) }
    specify { expect(described_class.get('B♯')).to be_enharmonic(described_class.get('C')) }
  end
end
