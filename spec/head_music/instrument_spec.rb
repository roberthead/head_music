require 'spec_helper'

describe Instrument do
  subject(:piano) { Instrument.get(:piano) }

  its(:name) { is_expected.to eq "piano" }

  context 'when given an instance' do
    let(:instance) { described_class.get('guitar') }

    it 'returns that instance' do
      expect(described_class.get(instance)).to be instance
    end
  end
end
