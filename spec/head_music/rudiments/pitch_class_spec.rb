# frozen_string_literal: true

require 'spec_helper'

describe HeadMusic::PitchClass do
  describe '.get' do
    subject(:pitch_class) { described_class.get(identifier) }

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
      let(:identifier) { 'D' }

      specify { expect(pitch_class).to eq 2 }
    end

    context 'when given a spelling and an octave' do
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
    specify { expect(described_class.get(53)).to eq described_class.get(5) }
  end

  describe 'addition' do
    specify { expect(described_class.get(11) + 3).to eq described_class.get(2) }
    specify { expect(described_class.get(5) + HeadMusic::ChromaticInterval.get(2)).to eq described_class.get(7) }
  end

  describe 'subtraction' do
    specify { expect(described_class.get(60) - 3).to eq described_class.get(9) }
    specify { expect(described_class.get(4) - HeadMusic::ChromaticInterval.get(3)).to eq described_class.get(1) }
  end

  describe '#intervals_to' do
    specify { expect(described_class.get(7).intervals_to(5).map(&:to_i)).to eq [-2, 10] }
    specify { expect(described_class.get(1).intervals_to(10).map(&:to_i)).to eq [-3, 9] }
    specify { expect(described_class.get(10).intervals_to(1).map(&:to_i)).to eq [3, -9] }
  end

  describe '#smallest_interval_to' do
    specify { expect(described_class.get(7).smallest_interval_to(5)).to eq(-2) }
    specify { expect(described_class.get(1).smallest_interval_to(10)).to eq(-3) }
    specify { expect(described_class.get(10).smallest_interval_to(1)).to eq(3) }
    specify { expect(described_class.get(11).smallest_interval_to(0)).to eq(1) }
    specify { expect(described_class.get(0).smallest_interval_to(11)).to eq(-1) }
  end

  describe '#enharmonic?' do
    specify { expect(described_class.get('G#')).to be_enharmonic(described_class.get('Ab')) }
    specify { expect(described_class.get('G#')).not_to be_enharmonic(described_class.get('A')) }

    specify { expect(described_class.get('Cb')).to be_enharmonic(described_class.get('B')) }
    specify { expect(described_class.get('E#')).to be_enharmonic(described_class.get('F')) }
    specify { expect(described_class.get('Fx')).to be_enharmonic(described_class.get('G')) }
  end

  describe '#white_key?' do
    specify { expect(described_class.get('C')).to be_white_key }
    specify { expect(described_class.get('B')).to be_white_key }

    specify { expect(described_class.get('G#')).not_to be_white_key }
    specify { expect(described_class.get('Gb')).not_to be_white_key }

    specify { expect(described_class.get('Fb')).to be_white_key }
    specify { expect(described_class.get('B#')).to be_white_key }
  end

  describe '#black_key?' do
    specify { expect(described_class.get('C')).not_to be_black_key }
    specify { expect(described_class.get('B')).not_to be_black_key }

    specify { expect(described_class.get('G#')).to be_black_key }
    specify { expect(described_class.get('Gb')).to be_black_key }

    specify { expect(described_class.get('Fb')).not_to be_black_key }
    specify { expect(described_class.get('B#')).not_to be_black_key }
  end

  describe '#to_s' do
    specify { expect(described_class.get('C').to_integer_notation).to eq '0' }
    specify { expect(described_class.get('C#').to_integer_notation).to eq '1' }
    specify { expect(described_class.get('Db').to_integer_notation).to eq '1' }
    specify { expect(described_class.get('D').to_integer_notation).to eq '2' }
    specify { expect(described_class.get('D#').to_integer_notation).to eq '3' }
    specify { expect(described_class.get('Eb').to_integer_notation).to eq '3' }
    specify { expect(described_class.get('E').to_integer_notation).to eq '4' }
    specify { expect(described_class.get('E#').to_integer_notation).to eq '5' }
    specify { expect(described_class.get('Fb').to_integer_notation).to eq '4' }
    specify { expect(described_class.get('F').to_integer_notation).to eq '5' }
    specify { expect(described_class.get('F#').to_integer_notation).to eq '6' }
    specify { expect(described_class.get('Gb').to_integer_notation).to eq '6' }
    specify { expect(described_class.get('G').to_integer_notation).to eq '7' }
    specify { expect(described_class.get('G#').to_integer_notation).to eq '8' }
    specify { expect(described_class.get('Ab').to_integer_notation).to eq '8' }
    specify { expect(described_class.get('A').to_integer_notation).to eq '9' }
    specify { expect(described_class.get('A#').to_integer_notation).to eq 't' }
    specify { expect(described_class.get('Bb').to_integer_notation).to eq 't' }
    specify { expect(described_class.get('B').to_integer_notation).to eq 'e' }
    specify { expect(described_class.get('B#').to_integer_notation).to eq '0' }
    specify { expect(described_class.get('Cb5').to_integer_notation).to eq 'e' }
  end

  describe '#smart_spelling' do
    specify do
      expect(described_class.get(6).smart_spelling).to eq 'F#'
    end

    specify do
      expect(described_class.get(6).smart_spelling(max_sharps_in_major_key_signature: 5)).to eq 'Gb'
    end

    specify do
      expect(described_class.get(11).smart_spelling(max_sharps_in_major_key_signature: 4)).to eq 'Cb'
    end
  end
end
