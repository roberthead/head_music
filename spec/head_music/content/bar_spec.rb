# frozen_string_literal: true

require 'spec_helper'

# TODO: Make this computed? Or representative of hardened computations?
describe HeadMusic::Bar do
  let(:composition) { HeadMusic::Composition.new(key_signature: 'D major', meter: '6/8') }
  subject(:bar) { described_class.new(composition) }

  its(:key_signature) { is_expected.to be_nil }
  its(:meter) { is_expected.to be_nil }

  context 'when specifying the key signature' do
    subject(:bar) { described_class.new(composition, key_signature: 'Bb minor') }

    its(:key_signature) { is_expected.to eq 'Bb minor' }
  end

  context 'when specifying the meter' do
    subject(:bar) { described_class.new(composition, meter: '5/4') }

    its(:meter) { is_expected.to eq '5/4' }
  end
end
