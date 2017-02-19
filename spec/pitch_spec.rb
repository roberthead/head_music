require 'spec_helper'

describe Pitch do
  describe '.get' do
    context 'when given an instance' do
      let(:instance) { described_class.get(65) }

      it 'returns that instance' do
        expect(described_class.get(instance)).to be instance
      end
    end

    context 'when given a spelling without an octave' do
      it 'defaults to octave 4' do
        expect(Pitch.get("G")).to eq "G4"
      end
    end

    context 'when given a midi note number' do
      specify { expect(Pitch.get(60)).to eq 'C4' }
      specify { expect(Pitch.get(70)).to eq 'Bb4' }
    end
  end

  describe 'math' do
    specify { expect(Pitch.get(60) + 12).to eq "C5" }
    specify { expect(Pitch.get("F#5") + 17).to eq "B6" }
    specify { expect(Pitch.get("F#5") - 7).to eq "B4" }
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
end
