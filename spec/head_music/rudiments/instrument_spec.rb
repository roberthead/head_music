# frozen_string_literal: true

require 'spec_helper'

describe HeadMusic::Instrument do
  describe '.get' do
    context 'when given an instance' do
      let(:instance) { described_class.get('guitar') }

      it 'returns that instance' do
        expect(described_class.get(instance)).to be instance
      end
    end
  end

  describe '.all' do
    subject { described_class.all }

    its(:length) { is_expected.to be > 1 }
  end

  context 'when piano' do
    subject(:piano) { described_class.get(:piano) }

    its(:name) { is_expected.to eq 'piano' }
    its(:default_clefs) { are_expected.to eq %w[treble_clef bass_clef] }
    its(:classifications) { are_expected.to include 'string' }
    its(:classifications) { are_expected.to include 'keyboard' }

    specify { expect(piano.translation(:de)).to eq 'Piano' }
  end

  context 'when organ' do
    subject(:organ) { described_class.get(:organ) }

    its(:name) { is_expected.to eq 'organ' }
    its(:default_clefs) { are_expected.to eq %w[treble_clef bass_clef bass_clef] }
    its(:classifications) { are_expected.to include 'keyboard' }
  end

  context 'when violin' do
    subject(:violin) { described_class.get(:violin) }

    its(:name) { is_expected.to eq 'violin' }
    its(:default_clefs) { are_expected.to eq ['treble_clef'] }
    its(:classifications) { are_expected.to include 'string' }
    its(:voice) { are_expected.to include 'soprano' }

    specify { expect(violin.translation(:it)).to eq 'violino' }
  end

  describe '#translation' do
    context 'when the instrument is unknown' do
      subject { described_class.get('floober') }

      it 'returns the name' do
        expect(subject.translation(:fr)).to eq 'floober'
      end
    end
  end
end
