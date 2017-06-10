require 'spec_helper'

describe Bar do
  let(:composition) { Composition.new(key_signature: 'D major', meter: '6/8') }
  subject(:bar) { Bar.new(composition) }

  its(:key_signature) { is_expected.to be_nil }
  its(:meter) { is_expected.to be_nil }

  context 'when specifying the key signature' do
    subject(:bar) { Bar.new(composition, key_signature: 'Bb minor') }

    its(:key_signature) { is_expected.to eq 'Bb minor' }
  end

  context 'when specifying the meter' do
    subject(:bar) { Bar.new(composition, meter: '5/4') }

    its(:meter) { is_expected.to eq '5/4' }
  end
end
