# frozen_string_literal: true

require 'spec_helper'

describe HeadMusic::PitchSet do
  context 'given a spread D major triad' do
    subject(:set) { described_class.new(%w[F#3 D4 A4]) }

    its(:reduction) { is_expected.to eq described_class.new(%w[F#3 A3 D4]) }

    specify { expect(set).to be_equivalent(described_class.new(%w[D5 F#5 A5 D6])) }
    specify { expect(set).to be_equivalent(described_class.new(%w[D3 F#3 A3])) }

    specify { expect(set).to eq(described_class.new(%w[F#3 D4 A4])) }
    specify { expect(set).to eq(described_class.new(%w[D4 F#3 A4])) }
    specify { expect(set).not_to eq(described_class.new(%w[D5 F#5 A5 D6])) }

    its(:size) { is_expected.to eq 3 }
    its(:pitch_class_size) { is_expected.to eq 3 }
  end

  context 'given a triad with doubling' do
    subject(:set) { described_class.new(%w[D5 F#5 A5 D6]) }

    its(:size) { is_expected.to eq 4 }
    its(:pitch_class_size) { is_expected.to eq 3 }
  end

  context 'given duplicate pitches' do
    subject(:set) { described_class.new(%w[D5 D5 F#5]) }

    its(:size) { is_expected.to eq 2 }
  end

  describe '#reduction' do
    subject(:set) { described_class.new(%w[D4 B4 G5]) }

    its(:reduction) { is_expected.to eq described_class.new(%w[D4 G4 B4]) }
  end
end
