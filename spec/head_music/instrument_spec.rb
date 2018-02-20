# frozen_string_literal: true

require 'spec_helper'

describe Instrument do
  context 'when given an instance' do
    let(:instance) { described_class.get('guitar') }

    it 'returns that instance' do
      expect(described_class.get(instance)).to be instance
    end
  end

  context 'when piano' do
    subject(:piano) { Instrument.get(:piano) }

    its(:name) { is_expected.to eq 'piano' }
    its(:default_system) { is_expected.to eq %i[treble bass] }
  end

  context 'when violin' do
    subject(:violin) { Instrument.get(:violin) }

    its(:name) { is_expected.to eq 'violin' }
    its(:default_clef) { is_expected.to eq :treble }
  end
end
