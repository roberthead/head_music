require 'spec_helper'

describe Spelling do
  describe '.get' do
    context 'when given an instance' do
      let(:instance) { described_class.get('A#5') }

      it 'returns that instance' do
        expect(described_class.get(instance)).to be instance
      end
    end

    context "for 'C'" do
      subject(:spelling) { Spelling.get('C') }

      its(:letter) { is_expected.to eq 'C' }
      its(:accidental) { is_expected.to be_nil }
      its(:pitch_class) { is_expected.to eq 0 }
      it { is_expected.to eq 'C' }
    end

    context "for 'F#'" do
      subject(:spelling) { Spelling.get('F#') }

      its(:letter) { is_expected.to eq 'F' }
      its(:accidental) { is_expected.to eq '#' }
      its(:pitch_class) { is_expected.to eq 6 }
      it { is_expected.to eq 'F#' }
    end

    context "for 'Bb'" do
      subject(:spelling) { Spelling.get('Bb') }

      its(:pitch_class) { is_expected.to eq 10 }
      it { is_expected.to eq 'Bb' }
    end

    context "for 'Cb'" do
      subject(:spelling) { Spelling.get('Cb') }

      its(:pitch_class) { is_expected.to eq 11 }
      it { is_expected.to eq 'Cb' }
    end

    context "for 'B#'" do
      subject(:spelling) { Spelling.get('B#') }

      its(:letter) { is_expected.to eq 'B' }
      its(:accidental) { is_expected.to eq '#' }
      its(:pitch_class) { is_expected.to eq 0 }
      it { is_expected.to eq 'B#' }
    end

    context "given a pitch class" do
      subject(:spelling) { Spelling.get(PitchClass.get(3)) }

      its(:pitch_class) { is_expected.to eq 3 }
      it { is_expected.to eq 'Eb' }
    end

    context "given a pitch class number" do
      subject(:spelling) { Spelling.get(1) }

      its(:pitch_class) { is_expected.to eq 1 }
      it { is_expected.to eq 'C#' }
    end

    context "given the pitch class number for F#/Gb" do
      subject(:spelling) { Spelling.get(6) }

      its(:pitch_class) { is_expected.to eq 6 }
      it { is_expected.to eq 'F#' }
    end
  end

  describe '#scale' do
    context 'without an argument' do
      subject(:scale) { Spelling.get('D').scale }

      its(:pitch_names) { are_expected.to eq %w[D E F# G A B C# D] }
    end

    context 'passed a scale type' do
      subject(:scale) { Spelling.get('E').scale(:minor) }

      its(:pitch_names) { are_expected.to eq %w[E F# G A B C D E] }
    end
  end
end
