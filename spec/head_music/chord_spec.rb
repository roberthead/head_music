# frozen_string_literal: true

require 'spec_helper'

describe HeadMusic::Chord do
  xdescribe '#reduction' do
    subject(:chord) { described_class.new(%w[D4 B4 G5]) }

    its(:reduction) { is_expected.to eq described_class.new(%w[D4 G4 B4]) }
  end

  describe '#consonant_triad?' do
    context 'given a minor chord' do
      context 'in root position' do
        subject(:chord) { described_class.new(%w[D F A]) }

        it { is_expected.to be_consonant_triad }
      end

      context 'in first inversion' do
        subject(:chord) { described_class.new(%w[F A D5]) }

        it { is_expected.to be_consonant_triad }
      end

      context 'in second inversion' do
        subject(:chord) { described_class.new(%w[A3 D F]) }

        it { is_expected.to be_consonant_triad }
      end
    end

    context 'given a major chord' do
      context 'in root position' do
        subject(:chord) { described_class.new(%w[G B D5]) }

        it { is_expected.to be_consonant_triad }
      end

      context 'in first inversion' do
        subject(:chord) { described_class.new(%w[B D5 G5]) }

        it { is_expected.to be_consonant_triad }
      end

      context 'in second inversion' do
        subject(:chord) { described_class.new(%w[D G B]) }

        it { is_expected.to be_consonant_triad }
      end

      xcontext 'spread' do
        subject(:chord) { described_class.new(%w[D4 B4 G5]) }

        it { is_expected.to be_consonant_triad }
      end
    end

    context 'given a seventh chord' do
      subject(:chord) { described_class.new(%w[C E G Bb]) }

      it { is_expected.not_to be_consonant_triad }
    end
  end
end
