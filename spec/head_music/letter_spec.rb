require 'spec_helper'

describe Letter do
  describe '.get' do
    context "fetched with 'A'" do
      subject(:letter) { Letter.get('A') }

      specify { expect(letter.pitch_class).to eq 9 }
      specify { expect(letter).to eq 'A' }
    end

    context "fetched with 'd#7'" do
      subject(:letter) { Letter.get('d#7') }

      specify { expect(letter.pitch_class).to eq 2 }
      specify { expect(letter).to eq 'D' }
    end

    context "fetched with 'X'" do
      subject(:letter) { Letter.get('X') }

      specify { expect(letter).to be_nil }
    end

    context 'when given an instance' do
      let(:instance) { described_class.get('C#4') }

      it 'returns that instance' do
        expect(described_class.get(instance)).to be instance
      end
    end
  end

  describe '.from_pitch_class' do
    specify { expect(Letter.from_pitch_class(0)).to eq 'C' }
    specify { expect(Letter.from_pitch_class(1)).to eq 'C' }
    specify { expect(Letter.from_pitch_class(2)).to eq 'D' }
    specify { expect(Letter.from_pitch_class(3)).to eq 'E' }
    specify { expect(Letter.from_pitch_class(4)).to eq 'E' }
    specify { expect(Letter.from_pitch_class(5)).to eq 'F' }
    specify { expect(Letter.from_pitch_class(6)).to eq 'F' }
    specify { expect(Letter.from_pitch_class(7)).to eq 'G' }
    specify { expect(Letter.from_pitch_class(8)).to eq 'A' }
    specify { expect(Letter.from_pitch_class(9)).to eq 'A' }
    specify { expect(Letter.from_pitch_class(10)).to eq 'B' }
    specify { expect(Letter.from_pitch_class(11)).to eq 'B' }
    specify { expect(Letter.from_pitch_class(12)).to eq 'C' }
  end

  describe '#cycle' do
    subject(:letter) { Letter.get('D') }

    its(:cycle) { is_expected.to eq %w[D E F G A B C] }
  end
end
