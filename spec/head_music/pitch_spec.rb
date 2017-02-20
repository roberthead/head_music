require 'spec_helper'

describe Pitch do
  describe '.get' do
    context 'when given an instance' do
      let(:instance) { described_class.get(65) }

      it 'returns that instance' do
        expect(described_class.get(instance)).to be instance
      end
    end

    context 'when given a spelling string without an octave' do
      it 'defaults to octave 4' do
        expect(Pitch.get('G')).to eq 'G4'
      end
    end

    context 'when given a spelling instance' do
      it 'defaults to octave 4' do
        expect(Pitch.get(Spelling.get('G#'))).to eq 'G#4'
      end
    end

    context 'when given a midi note number' do
      specify { expect(Pitch.get(60)).to eq 'C4' }
      specify { expect(Pitch.get(70)).to eq 'Bb4' }
    end
  end

  describe 'math' do
    specify { expect(Pitch.get(60) + 12).to eq 'C5' }
    specify { expect(Pitch.get('F#5') + 17).to eq 'B6' }
    specify { expect(Pitch.get('F#5') - 7).to eq 'B4' }
  end

  describe 'comparison' do
    subject(:pitch) { Pitch.get('G#3') }

    it { is_expected.to be == 'G#3' }
    it { is_expected.not_to be == 'Ab3' }

    it { is_expected.to be < Pitch.get('D4') }
    it { is_expected.to be > Pitch.get('D3') }

    it { is_expected.to be_enharmonic(Pitch.get('Ab3')) }
    it { is_expected.not_to be_enharmonic(Pitch.get('C7')) }
    it { is_expected.not_to be_enharmonic(Pitch.get('G#4')) }
  end

  describe 'construction from a string' do
    context "for 'C'" do
      subject(:pitch) { Pitch.get('C4') }

      its(:letter) { is_expected.to eq 'C' }
      its(:accidental) { is_expected.to be_nil }
      its(:pitch_class) { is_expected.to eq 0 }
      its(:octave) { is_expected.to eq 4 }
      its(:midi_note_number) { is_expected.to eq 60 }
      it { is_expected.to eq 'C4' }
    end

    context "for 'Cb4'" do
      subject(:pitch) { Pitch.get('Cb4') }

      its(:octave) { is_expected.to eq 4 }
      its(:midi_note_number) { is_expected.to eq 59 }
    end

    context "for 'B#4'" do
      subject(:pitch) { Pitch.get('B#4') }

      its(:octave) { is_expected.to eq 4 }
      its(:midi_note_number) { is_expected.to eq 72 }
    end

    context "for 'F#-1'" do
      subject(:pitch) { Pitch.get('F#-1') }

      its(:letter) { is_expected.to eq 'F' }
      its(:accidental) { is_expected.to eq '#' }
      its(:pitch_class) { is_expected.to eq 6 }
      its(:octave) { is_expected.to eq -1 }
      its(:midi_note_number) { is_expected.to eq 6 }
      it { is_expected.to eq 'F#-1' }
    end

    context "for 'Bb5'" do
      subject(:pitch) { Pitch.get('Bb5') }

      its(:letter) { is_expected.to eq 'B' }
      its(:accidental) { is_expected.to eq 'b' }
      its(:pitch_class) { is_expected.to eq 10 }
      its(:octave) { is_expected.to eq 5 }
      its(:midi_note_number) { is_expected.to eq 82 }
      it { is_expected.to eq 'Bb5' }
    end

    context "for 'Eb7'" do
      subject(:pitch) { Pitch.get('Eb7') }

      its(:letter) { is_expected.to eq 'E' }
      its(:accidental) { is_expected.to eq 'b' }
      its(:pitch_class) { is_expected.to eq 3 }
      its(:octave) { is_expected.to eq 7 }
      its(:midi_note_number) { is_expected.to eq 99 }
      it { is_expected.to eq 'Eb7' }
    end

    context "for 'biscuit'" do
      subject(:pitch) { Pitch.get('biscuit') }

      it { is_expected.to be_nil }
    end
  end

  describe '#scale' do
    context 'without an argument' do
      subject(:scale) { Pitch.get('D4').scale }

      its(:spellings) { are_expected.to eq %w[D E F# G A B C# D] }
    end

    context 'passed a scale type' do
      subject(:scale) { Pitch.get('E').scale(:minor) }

      its(:spellings) { are_expected.to eq %w[E F# G A B C D E] }
    end
  end

  describe '#letter_cycle' do
    subject(:pitch) { Pitch.get('D') }

    its(:letter_cycle) { is_expected.to eq %w[D E F G A B C] }
  end

  describe 'addition' do
    let(:pitch) { Pitch.get('A4') }

    context 'when adding an interval' do
      it 'returns the new pitch' do
        expect(pitch + Interval.get(9)).to eq 'F#5'
      end
    end

    context 'when adding an integer' do
      it 'returns the new pitch' do
        expect(pitch + 9).to eq 'F#5'
      end
    end
  end

  describe 'subtraction' do
    let(:pitch) { Pitch.get('A5') }

    context 'when subtracting an interval' do
      it 'returns the new pitch' do
        expect(pitch - Interval.get(10)).to eq 'B4'
      end
    end

    context 'when subtracting an integer' do
      it 'returns the new pitch' do
        expect(pitch - 10).to eq 'B4'
      end
    end

    context 'when subtracting a pitch' do
      it 'returns the interval' do
        expect(pitch - Pitch.get('B4')).to eq 10
      end
    end
  end
end
