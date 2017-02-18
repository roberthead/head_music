require 'spec_helper'

describe Accidental do
  describe '.get' do
    specify { expect(Accidental.get('#').semitones).to eq 1 }
    specify { expect(Accidental.get(1)).to eq '#' }
    specify { expect(Accidental.get('foo')).to be_nil }
    specify { expect(Accidental.get(nil)).to be_nil }
    specify { expect(Accidental.get('')).to be_nil }

    context 'when given an instance' do
      let(:instance) { described_class.get('#') }

      it 'returns that instance' do
        expect(described_class.get(instance)).to be instance
      end
    end
  end

  describe '#semitones' do
    specify { expect(Accidental.get('#').semitones).to eq 1 }
    specify { expect(Accidental.get('##').semitones).to eq 2 }
    specify { expect(Accidental.get('b').semitones).to eq -1 }
    specify { expect(Accidental.get('bb').semitones).to eq -2 }
  end

  describe 'equality' do
    specify { expect(Accidental.get('#')).to eq '#' }
    specify { expect(Accidental.get('bb')).to eq 'bb' }
  end
end
