# frozen_string_literal: true

require 'spec_helper'

describe HeadMusic::Staff do
  subject { described_class.new(:treble) }

  its(:clef) { is_expected.to eq :treble }
  its(:line_count) { is_expected.to be 5 }
  its(:instrument) { is_expected.to be nil }

  context 'when passed an instrument' do
    subject { described_class.new(:alto, instrument: :viola) }

    its(:clef) { is_expected.to eq :alto }
    its(:line_count) { is_expected.to be 5 }
    its(:instrument) { is_expected.to eq :viola }
  end
end
