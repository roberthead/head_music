# frozen_string_literal: true

require 'spec_helper'

describe HeadMusic::Pitch do
  describe '.get' do
    context 'when given an instance' do
      let(:instance) { described_class.get(65) }

      it 'returns that instance' do
        expect(described_class.get(instance)).to be instance
      end
    end

    context 'when given a spelling string without an octave' do
      it 'defaults to octave 4' do
        expect(described_class.get('G')).to eq 'G4'
      end
    end

    context 'when given a spelling instance' do
      it 'defaults to octave 4' do
        expect(described_class.get(HeadMusic::Spelling.get('G#'))).to eq 'G#4'
      end
    end

    context 'when given a midi note number' do
      specify { expect(described_class.get(60)).to eq 'C4' }
      specify { expect(described_class.get(70)).to eq 'A#4' }
    end

    context 'when given a pitch class' do
      specify { expect(described_class.get(HeadMusic::PitchClass.get('C'))).to eq 'C4' }
      specify { expect(described_class.get(HeadMusic::PitchClass.get('D'))).to eq 'D4' }
    end
  end

  describe 'math' do
    specify { expect(described_class.get(60) + 12).to eq 'C5' }
    specify { expect(described_class.get('F#5') + 17).to eq 'B6' }
    specify { expect(described_class.get('F#5') - 7).to eq 'B4' }
  end

  describe 'comparison' do
    subject(:pitch) { described_class.get('G#3') }

    it { is_expected.to be == 'G#3' }
    it { is_expected.not_to be == 'Ab3' }

    it { is_expected.to be < described_class.get('D4') }
    it { is_expected.to be > described_class.get('D3') }

    it { is_expected.to be_enharmonic(described_class.get('Ab3')) }
    it { is_expected.to be_enharmonic_equivalent(described_class.get('Ab3')) }

    it { is_expected.not_to be_enharmonic(described_class.get('C7')) }
    it { is_expected.not_to be_enharmonic(described_class.get('G#4')) }
  end

  describe 'construction from a string' do
    context "for 'C'" do
      subject(:pitch) { described_class.get('C4') }

      its(:letter_name) { is_expected.to eq 'C' }
      its(:sign) { is_expected.to be_nil }
      its(:pitch_class) { is_expected.to eq 0 }
      its(:octave) { is_expected.to eq 4 }
      its(:midi_note_number) { is_expected.to eq 60 }
      it { is_expected.to eq 'C4' }
    end

    context "for 'Cb4'" do
      subject(:pitch) { described_class.get('Cb4') }

      its(:octave) { is_expected.to eq 4 }
      its(:midi_note_number) { is_expected.to eq 59 }
    end

    context "for 'B#4'" do
      subject(:pitch) { described_class.get('B#4') }

      its(:octave) { is_expected.to eq 4 }
      its(:midi_note_number) { is_expected.to eq 72 }
      its(:frequency) { is_expected.to be_within(0.1).of(523.2) }
    end

    context "for 'F#-1'" do
      subject(:pitch) { described_class.get('F#-1') }

      its(:letter_name) { is_expected.to eq 'F' }
      its(:sign) { is_expected.to eq '#' }
      its(:pitch_class) { is_expected.to eq 6 }
      its(:octave) { is_expected.to eq(-1) }
      its(:midi_note_number) { is_expected.to eq 6 }
      its(:frequency) { is_expected.to be_within(0.1).of(11.5) }
      it { is_expected.to eq 'F#-1' }
    end

    context "for 'Bb5'" do
      subject(:pitch) { described_class.get('Bb5') }

      its(:letter_name) { is_expected.to eq 'B' }
      its(:sign) { is_expected.to eq 'b' }
      its(:pitch_class) { is_expected.to eq 10 }
      its(:octave) { is_expected.to eq 5 }
      its(:midi_note_number) { is_expected.to eq 82 }
      its(:frequency) { is_expected.to be_within(0.1).of(932.3) }
      it { is_expected.to eq 'Bb5' }
    end

    context "for 'Eb7'" do
      subject(:pitch) { described_class.get('Eb7') }

      its(:letter_name) { is_expected.to eq 'E' }
      its(:sign) { is_expected.to eq 'b' }
      its(:pitch_class) { is_expected.to eq 3 }
      its(:octave) { is_expected.to eq 7 }
      its(:midi_note_number) { is_expected.to eq 99 }
      its(:frequency) { is_expected.to be_within(0.1).of(2489.0) }
      it { is_expected.to eq 'Eb7' }
    end

    context "for 'biscuit'" do
      subject(:pitch) { described_class.get('biscuit') }

      it { is_expected.to be_nil }
    end

    context 'for nil' do
      subject(:pitch) { described_class.get(nil) }

      it { is_expected.to be_nil }
    end
  end

  describe '#scale' do
    context 'without an argument' do
      subject(:scale) { described_class.get('D4').scale }

      its(:spellings) { are_expected.to eq %w[D E F♯ G A B C♯ D] }
    end

    context 'passed a scale type' do
      subject(:scale) { described_class.get('E').scale(:minor) }

      its(:spellings) { are_expected.to eq %w[E F♯ G A B C D E] }
    end
  end

  describe '#letter_name_cycle' do
    subject(:pitch) { described_class.get('D') }

    its(:letter_name_cycle) { is_expected.to eq %w[D E F G A B C] }
  end

  describe '#octave_equivalent?' do
    specify { expect(described_class.get('D1')).to be_octave_equivalent(described_class.get('D4')) }
    specify { expect(described_class.get('D4')).not_to be_octave_equivalent(described_class.get('D4')) }
    specify { expect(described_class.get('E5')).not_to be_octave_equivalent(described_class.get('F♭6')) }
  end

  describe 'addition' do
    let(:pitch) { described_class.get('A4') }

    context 'when adding an interval' do
      it 'returns the new pitch' do
        expect(pitch + HeadMusic::Interval.get(9)).to eq 'F#5'
      end
    end

    context 'when adding an integer' do
      it 'returns the new pitch' do
        expect(pitch + 9).to eq 'F#5'
      end
    end
  end

  describe 'subtraction' do
    let(:pitch) { described_class.get('A5') }

    context 'when subtracting an interval' do
      it 'returns the new pitch' do
        expect(pitch - HeadMusic::Interval.get(10)).to eq 'B4'
      end
    end

    context 'when subtracting an integer' do
      it 'returns the new pitch' do
        expect(pitch - 10).to eq 'B4'
      end
    end

    context 'when subtracting a pitch' do
      it 'returns the interval' do
        expect(pitch - described_class.get('B4')).to eq 10
      end
    end
  end
end
