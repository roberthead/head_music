# frozen_string_literal: true

require 'spec_helper'

describe HeadMusic::PitchSet::Analysis do
  subject(:analysis) { described_class.new(set) }

  context 'when the set has zero pitches' do
    let(:set) { HeadMusic::PitchSet.new([]) }

    it { is_expected.to be_empty }
    it { is_expected.to be_empty_set }
    it { is_expected.not_to be_monad }
    it { is_expected.not_to be_dyad }
    it { is_expected.not_to be_trichord }
    it { is_expected.not_to be_triad }
    it { is_expected.not_to be_tetrachord }
    it { is_expected.not_to be_pentachord }
    it { is_expected.not_to be_hexachord }
    it { is_expected.not_to be_heptachord }
    it { is_expected.not_to be_octachord }
    it { is_expected.not_to be_nonachord }
    it { is_expected.not_to be_decachord }
    it { is_expected.not_to be_undecachord }
    it { is_expected.not_to be_dodecachord }
  end

  context 'when the set has one pitch' do
    let(:set) { HeadMusic::PitchSet.new(%w[A4]) }

    it { is_expected.not_to be_empty }
    it { is_expected.not_to be_empty_set }
    it { is_expected.to be_monad }
    it { is_expected.not_to be_dyad }
    it { is_expected.not_to be_trichord }
    it { is_expected.not_to be_triad }
    it { is_expected.not_to be_tetrachord }
    it { is_expected.not_to be_pentachord }
    it { is_expected.not_to be_hexachord }
    it { is_expected.not_to be_heptachord }
    it { is_expected.not_to be_octachord }
    it { is_expected.not_to be_nonachord }
    it { is_expected.not_to be_decachord }
    it { is_expected.not_to be_undecachord }
    it { is_expected.not_to be_dodecachord }
  end

  context 'when the set has two pitches' do
    let(:set) { HeadMusic::PitchSet.new(%w[A3 D4]) }

    it { is_expected.not_to be_empty }
    it { is_expected.not_to be_empty_set }
    it { is_expected.not_to be_monad }
    it { is_expected.to be_dyad }
    it { is_expected.not_to be_trichord }
    it { is_expected.not_to be_triad }
    it { is_expected.not_to be_tetrachord }
    it { is_expected.not_to be_pentachord }
    it { is_expected.not_to be_hexachord }
    it { is_expected.not_to be_heptachord }
    it { is_expected.not_to be_octachord }
    it { is_expected.not_to be_nonachord }
    it { is_expected.not_to be_decachord }
    it { is_expected.not_to be_undecachord }
    it { is_expected.not_to be_dodecachord }
  end

  context 'when the set has three pitches' do
    context 'given a minor chord' do
      context 'in root position' do
        let(:set) { HeadMusic::PitchSet.new(%w[D F A]) }

        it { is_expected.to be_consonant_triad }
        it { is_expected.to be_root_triad }
        it { is_expected.not_to be_major_triad }
        it { is_expected.to be_minor_triad }
      end

      context 'in first inversion' do
        let(:set) { HeadMusic::PitchSet.new(%w[F A D5]) }

        it { is_expected.to be_consonant_triad }
        it { is_expected.not_to be_root_triad }
        it { is_expected.not_to be_major_triad }
        it { is_expected.to be_minor_triad }
      end

      context 'in second inversion' do
        let(:set) { HeadMusic::PitchSet.new(%w[A3 D F]) }

        it { is_expected.to be_consonant_triad }
        it { is_expected.not_to be_root_triad }
        it { is_expected.not_to be_major_triad }
        it { is_expected.to be_minor_triad }
      end

      context 'spread' do
        let(:set) { HeadMusic::PitchSet.new(%w[B3 F#4 D5]) }

        it { is_expected.to be_consonant_triad }
        it { is_expected.to be_root_triad }
        it { is_expected.not_to be_major_triad }
        it { is_expected.to be_minor_triad }
      end

      context 'spread wide' do
        let(:set) { HeadMusic::PitchSet.new(%w[D3 Bb4 G6]) }

        it { is_expected.to be_consonant_triad }
        it { is_expected.not_to be_root_triad }
        it { is_expected.not_to be_major_triad }
        it { is_expected.to be_minor_triad }
      end
    end

    context 'given a major chord' do
      context 'in root position' do
        let(:set) { HeadMusic::PitchSet.new(%w[G B D5]) }

        it { is_expected.to be_consonant_triad }
        it { is_expected.to be_root_triad }
        it { is_expected.not_to be_first_inversion_triad }
        it { is_expected.not_to be_second_inversion_triad }
        it { is_expected.to be_major_triad }
        it { is_expected.not_to be_minor_triad }
      end

      context 'in first inversion' do
        let(:set) { HeadMusic::PitchSet.new(%w[B D5 G5]) }

        it { is_expected.to be_consonant_triad }
        it { is_expected.not_to be_root_triad }
        it { is_expected.to be_first_inversion_triad }
        it { is_expected.not_to be_second_inversion_triad }
        it { is_expected.to be_major_triad }
        it { is_expected.not_to be_minor_triad }
      end

      context 'in second inversion' do
        let(:set) { HeadMusic::PitchSet.new(%w[D G B]) }

        it { is_expected.to be_consonant_triad }
        it { is_expected.not_to be_root_triad }
        it { is_expected.not_to be_first_inversion_triad }
        it { is_expected.to be_second_inversion_triad }
        it { is_expected.to be_major_triad }
        it { is_expected.not_to be_minor_triad }
      end

      context 'spread' do
        let(:set) { HeadMusic::PitchSet.new(%w[B3 F#4 D#5]) }

        it { is_expected.to be_consonant_triad }
        it { is_expected.to be_root_triad }
        it { is_expected.not_to be_first_inversion_triad }
        it { is_expected.not_to be_second_inversion_triad }
        it { is_expected.to be_major_triad }
        it { is_expected.not_to be_minor_triad }
      end

      context 'spread wide' do
        let(:set) { HeadMusic::PitchSet.new(%w[D3 B4 G6]) }

        it { is_expected.to be_consonant_triad }
        it { is_expected.not_to be_root_triad }
        it { is_expected.not_to be_first_inversion_triad }
        it { is_expected.to be_second_inversion_triad }
        it { is_expected.to be_major_triad }
        it { is_expected.not_to be_minor_triad }
      end
    end
  end

  context 'when the set has three pitches' do
    context 'given a seventh chord' do
      let(:set) { HeadMusic::PitchSet.new(%w[C E G Bb]) }

      it { is_expected.not_to be_consonant_triad }
      it { is_expected.not_to be_root_triad }
      it { is_expected.not_to be_first_inversion_triad }
      it { is_expected.not_to be_second_inversion_triad }
      it { is_expected.not_to be_major_triad }
      it { is_expected.not_to be_minor_triad }
    end
  end
end
