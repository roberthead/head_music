require 'spec_helper'

describe HeadMusic::Sign do
  describe '.get' do
    specify { expect(HeadMusic::Sign.get('#').identifier).to eq :sharp }
    specify { expect(HeadMusic::Sign.get('sharp').identifier).to eq :sharp }
    specify { expect(HeadMusic::Sign.get(:sharp).identifier).to eq :sharp }
    specify { expect(HeadMusic::Sign.get("\u266F").identifier).to eq :sharp }
    specify { expect(HeadMusic::Sign.get('&#9837;').identifier).to eq :flat }

    specify { expect(HeadMusic::Sign.get('foo')).to be_nil }
    specify { expect(HeadMusic::Sign.get(nil)).to be_nil }
    specify { expect(HeadMusic::Sign.get('')).to be_nil }

    context 'when given an instance' do
      let(:instance) { described_class.get('#') }

      it 'returns that instance' do
        expect(described_class.get(instance)).to be instance
      end
    end
  end

  describe '#to_s' do
    specify { expect(HeadMusic::Sign.get(:sharp)).to eq '♯' }
    specify { expect(HeadMusic::Sign.get(:flat)).to eq '♭' }
    specify { expect(HeadMusic::Sign.get(:double_sharp)).to eq '𝄪' }
    specify { expect(HeadMusic::Sign.get(:double_flat)).to eq '𝄫' }
    specify { expect(HeadMusic::Sign.get(:natural)).to eq '♮' }
  end

  describe '#semitones' do
    specify { expect(HeadMusic::Sign.get('#').semitones).to eq 1 }
    specify { expect(HeadMusic::Sign.get('##').semitones).to eq 2 }
    specify { expect(HeadMusic::Sign.get('b').semitones).to eq -1 }
    specify { expect(HeadMusic::Sign.get('bb').semitones).to eq -2 }
  end

  describe 'equality' do
    specify { expect(HeadMusic::Sign.get('#')).to eq '♯' }
    specify { expect(HeadMusic::Sign.get('bb')).to eq 'bb' }
  end

  describe '.for_cents' do
    specify { expect(HeadMusic::Sign.by(:cents, 100)).to eq '#' }
    specify { expect(HeadMusic::Sign.by(:semitones, 1)).to eq '#' }
    specify { expect(HeadMusic::Sign.by(:cents, -100)).to eq 'b' }
    specify { expect(HeadMusic::Sign.by(:semitones, -1)).to eq :flat }
    specify { expect(HeadMusic::Sign.by(:cents, 0)).to eq :natural }
    specify { expect(HeadMusic::Sign.by(:semitones, 0)).to eq '♮' }
  end
end
