# frozen_string_literal: true

require 'spec_helper'

describe HeadMusic::ReferencePitch do
  it { is_expected.to respond_to(:pitch) }
  it { is_expected.to respond_to(:frequency) }

  context 'when not given any arguments' do
    subject(:tuning) { described_class.new }

    its(:pitch) { is_expected.to eq 'A4' }
    its(:frequency) { is_expected.to eq 440.0 }
  end

  context '.a440' do
    subject(:tuning) { described_class.a440 }

    its(:pitch) { is_expected.to eq 'A4' }
    its(:frequency) { is_expected.to eq 440.0 }
  end

  context '.scientific' do
    subject(:tuning) { described_class.scientific }

    its(:pitch) { is_expected.to eq 'C4' }
    its(:frequency) { is_expected.to eq 256.0 }
  end

  context '.french' do
    subject(:tuning) { described_class.french }

    its(:pitch) { is_expected.to eq 'A4' }
    its(:frequency) { is_expected.to eq 435 }
  end
end
