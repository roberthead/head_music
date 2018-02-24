# frozen_string_literal: true

require 'spec_helper'

describe PitchClass do
  describe '.get' do
    subject(:pitch_class) { PitchClass.get(identifier) }

    context 'when constructed with a number between zero and eleven' do
      let(:identifier) { rand(12) }

      specify { expect(pitch_class.number).to eq identifier }
      specify { expect(pitch_class.to_i).to eq identifier }
    end

    context 'when constructed with a midi note number' do
      let(:identifier) { 53 } # F3

      specify { expect(pitch_class).to eq 5 }
    end

    context 'when given a spelling' do
      let(:identifier) { 'D#-1' }

      specify { expect(pitch_class).to eq 3 }
    end

    context 'when given an instance' do
      let(:instance) { described_class.get(7) }

      it 'returns that instance' do
        expect(described_class.get(instance)).to be instance
      end
    end
  end

  describe 'equality' do
    specify { expect(PitchClass.get(53)).to eq PitchClass.get(5) }
  end

  describe 'addition' do
    specify { expect(PitchClass.get(11) + 3).to eq PitchClass.get(2) }
    specify { expect(PitchClass.get(5) + Interval.get(2)).to eq PitchClass.get(7) }
  end

  describe 'subtraction' do
    specify { expect(PitchClass.get(60) - 3).to eq PitchClass.get(9) }
    specify { expect(PitchClass.get(4) - Interval.get(3)).to eq PitchClass.get(1) }
  end

  describe '#intervals_to' do
    specify { expect(PitchClass.get(7).intervals_to(5).map(&:to_i)).to eq [-2, 10] }
    specify { expect(PitchClass.get(1).intervals_to(10).map(&:to_i)).to eq [-3, 9] }
    specify { expect(PitchClass.get(10).intervals_to(1).map(&:to_i)).to eq [3, -9] }
  end

  describe '#smallest_interval_to' do
    specify { expect(PitchClass.get(7).smallest_interval_to(5)).to eq(-2) }
    specify { expect(PitchClass.get(1).smallest_interval_to(10)).to eq(-3) }
    specify { expect(PitchClass.get(10).smallest_interval_to(1)).to eq(3) }
    specify { expect(PitchClass.get(11).smallest_interval_to(0)).to eq(1) }
    specify { expect(PitchClass.get(0).smallest_interval_to(11)).to eq(-1) }
  end

  describe '#enharmonic?' do
    subject { PitchClass.get('G#') }

    it { is_expected.to be_enharmonic(PitchClass.get('Ab')) }
    it { is_expected.not_to be_enharmonic(PitchClass.get('A')) }
  end
end
