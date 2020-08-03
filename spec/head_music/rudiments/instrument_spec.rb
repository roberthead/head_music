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

  context 'when piano' do
    subject(:piano) { described_class.get(:piano) }

    its(:name) { is_expected.to eq 'piano' }
    its(:default_clefs) { are_expected.to eq %w[treble_clef bass_clef] }
  end

  context 'when violin' do
    subject(:violin) { described_class.get(:violin) }

    its(:name) { is_expected.to eq 'violin' }
    its(:default_clefs) { are_expected.to eq ['treble_clef'] }
  end
end
