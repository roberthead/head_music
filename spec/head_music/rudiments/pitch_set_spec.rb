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

  describe 'analysis' do
    context 'when the set has zero pitches' do
      subject(:set) { HeadMusic::PitchSet.new([]) }

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
      it { is_expected.not_to be_tertial }
    end

    context 'when the set has one pitch' do
      subject(:set) { HeadMusic::PitchSet.new(%w[A4]) }

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
      it { is_expected.not_to be_tertial }
    end

    context 'when the set has two pitches' do
      subject(:set) { HeadMusic::PitchSet.new(%w[A3 D4]) }

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

      context 'when the pitches are a third apart' do
        subject(:set) { HeadMusic::PitchSet.new(%w[D4 F#4]) }

        it { is_expected.to be_tertial }
      end

      context 'when the pitches are a compound sixth apart' do
        subject(:set) { HeadMusic::PitchSet.new(%w[F#4 D6]) }

        it { is_expected.to be_tertial }
      end
    end

    context 'when the set has three pitches' do
      context 'given a minor chord' do
        context 'in root position' do
          subject(:set) { HeadMusic::PitchSet.new(%w[D F A]) }

          it { is_expected.to be_triad }
          it { is_expected.to be_consonant_triad }
          it { is_expected.to be_root_position_triad }
          it { is_expected.not_to be_major_triad }
          it { is_expected.to be_minor_triad }
          it { is_expected.to be_tertial }
        end

        context 'in first inversion' do
          subject(:set) { HeadMusic::PitchSet.new(%w[F A D5]) }

          it { is_expected.to be_triad }
          it { is_expected.to be_consonant_triad }
          it { is_expected.not_to be_root_position_triad }
          it { is_expected.not_to be_major_triad }
          it { is_expected.to be_minor_triad }
          it { is_expected.to be_tertial }
        end

        context 'in second inversion' do
          subject(:set) { HeadMusic::PitchSet.new(%w[A3 D F]) }

          it { is_expected.to be_triad }
          it { is_expected.to be_consonant_triad }
          it { is_expected.not_to be_root_position_triad }
          it { is_expected.not_to be_major_triad }
          it { is_expected.to be_minor_triad }
          it { is_expected.to be_tertial }
        end

        context 'spread' do
          subject(:set) { HeadMusic::PitchSet.new(%w[B3 F#4 D5]) }

          it { is_expected.to be_triad }
          it { is_expected.to be_consonant_triad }
          it { is_expected.to be_root_position_triad }
          it { is_expected.not_to be_major_triad }
          it { is_expected.to be_minor_triad }
          it { is_expected.to be_tertial }
        end

        context 'spread wide' do
          subject(:set) { HeadMusic::PitchSet.new(%w[D3 Bb4 G6]) }

          it { is_expected.to be_triad }
          it { is_expected.to be_consonant_triad }
          it { is_expected.not_to be_root_position_triad }
          it { is_expected.not_to be_major_triad }
          it { is_expected.to be_minor_triad }
          it { is_expected.to be_tertial }
        end
      end

      context 'given a major chord' do
        context 'in root position' do
          subject(:set) { HeadMusic::PitchSet.new(%w[G B D5]) }

          it { is_expected.to be_triad }
          it { is_expected.to be_consonant_triad }
          it { is_expected.to be_root_position_triad }
          it { is_expected.not_to be_first_inversion_triad }
          it { is_expected.not_to be_second_inversion_triad }
          it { is_expected.to be_major_triad }
          it { is_expected.not_to be_minor_triad }
          it { is_expected.not_to be_diminished_triad }
          it { is_expected.to be_tertial }
        end

        context 'in first inversion' do
          subject(:set) { HeadMusic::PitchSet.new(%w[B D5 G5]) }

          it { is_expected.to be_triad }
          it { is_expected.to be_consonant_triad }
          it { is_expected.not_to be_root_position_triad }
          it { is_expected.to be_first_inversion_triad }
          it { is_expected.not_to be_second_inversion_triad }
          it { is_expected.to be_major_triad }
          it { is_expected.not_to be_minor_triad }
          it { is_expected.to be_tertial }
        end

        context 'in second inversion' do
          subject(:set) { HeadMusic::PitchSet.new(%w[D G B]) }

          it { is_expected.to be_triad }
          it { is_expected.to be_consonant_triad }
          it { is_expected.not_to be_root_position_triad }
          it { is_expected.not_to be_first_inversion_triad }
          it { is_expected.to be_second_inversion_triad }
          it { is_expected.to be_major_triad }
          it { is_expected.not_to be_minor_triad }
          it { is_expected.to be_tertial }
        end

        context 'spread' do
          subject(:set) { HeadMusic::PitchSet.new(%w[B3 F#4 D#5]) }

          it { is_expected.to be_triad }
          it { is_expected.to be_consonant_triad }
          it { is_expected.to be_root_position_triad }
          it { is_expected.not_to be_first_inversion_triad }
          it { is_expected.not_to be_second_inversion_triad }
          it { is_expected.to be_major_triad }
          it { is_expected.not_to be_minor_triad }
          it { is_expected.to be_tertial }
        end

        context 'spread wide' do
          subject(:set) { HeadMusic::PitchSet.new(%w[D3 B4 G6]) }

          it { is_expected.to be_triad }
          it { is_expected.to be_consonant_triad }
          it { is_expected.not_to be_root_position_triad }
          it { is_expected.not_to be_first_inversion_triad }
          it { is_expected.to be_second_inversion_triad }
          it { is_expected.to be_major_triad }
          it { is_expected.not_to be_minor_triad }
          it { is_expected.not_to be_diminished_triad }
          it { is_expected.to be_tertial }
        end
      end

      context 'when given a diminished triad' do
        subject(:set) { HeadMusic::PitchSet.new(%w[C4 Eb4 Gb4]) }

        it { is_expected.to be_triad }
        it { is_expected.not_to be_consonant_triad }
        it { is_expected.to be_root_position_triad }
        it { is_expected.not_to be_first_inversion_triad }
        it { is_expected.not_to be_second_inversion_triad }
        it { is_expected.not_to be_major_triad }
        it { is_expected.not_to be_minor_triad }
        it { is_expected.to be_diminished_triad }
        it { is_expected.to be_tertial }
      end

      context 'when given an inverted diminished triad' do
        subject(:set) { HeadMusic::PitchSet.new(%w[Eb4 Gb4 C5]) }

        it { is_expected.to be_triad }
        it { is_expected.not_to be_consonant_triad }
        it { is_expected.not_to be_root_position_triad }
        it { is_expected.to be_first_inversion_triad }
        it { is_expected.not_to be_second_inversion_triad }
        it { is_expected.not_to be_major_triad }
        it { is_expected.not_to be_minor_triad }
        it { is_expected.to be_diminished_triad }
        it { is_expected.not_to be_augmented_triad }
        it { is_expected.to be_tertial }
      end

      context 'when given an augmented triad' do
        subject(:set) { HeadMusic::PitchSet.new(%w[C4 E4 G#4]) }

        it { is_expected.to be_triad }
        it { is_expected.not_to be_consonant_triad }
        it { is_expected.to be_root_position_triad }
        it { is_expected.not_to be_first_inversion_triad }
        it { is_expected.not_to be_second_inversion_triad }
        it { is_expected.not_to be_major_triad }
        it { is_expected.not_to be_minor_triad }
        it { is_expected.not_to be_diminished_triad }
        it { is_expected.to be_augmented_triad }
        it { is_expected.to be_tertial }
      end

      context 'when given an augmented triad in second inversion' do
        subject(:set) { HeadMusic::PitchSet.new(%w[G#3 C4 E4]) }

        it { is_expected.to be_triad }
        it { is_expected.not_to be_consonant_triad }
        it { is_expected.not_to be_root_position_triad }
        it { is_expected.not_to be_first_inversion_triad }
        it { is_expected.to be_second_inversion_triad }
        it { is_expected.not_to be_major_triad }
        it { is_expected.not_to be_minor_triad }
        it { is_expected.not_to be_diminished_triad }
        it { is_expected.to be_augmented_triad }
        it { is_expected.to be_tertial }
      end

      context 'when given a non-triad' do
        subject(:set) { HeadMusic::PitchSet.new(%w[C4 D4 F4]) }

        it { is_expected.not_to be_consonant_triad }
        it { is_expected.not_to be_root_position_triad }
        it { is_expected.not_to be_first_inversion_triad }
        it { is_expected.not_to be_second_inversion_triad }
        it { is_expected.not_to be_major_triad }
        it { is_expected.not_to be_minor_triad }
        it { is_expected.not_to be_tertial }
      end
    end

    context 'when the set has four pitches' do
      context 'given a seventh chord in root position' do
        subject(:set) { HeadMusic::PitchSet.new(%w[C E G Bb]) }

        it { is_expected.not_to be_triad }
        it { is_expected.to be_seventh_chord }
        it { is_expected.to be_root_position_seventh_chord }
        it { is_expected.not_to be_first_inversion_seventh_chord }
        it { is_expected.not_to be_second_inversion_seventh_chord }
        it { is_expected.not_to be_third_inversion_seventh_chord }
        it { is_expected.to be_tertial }
      end

      context 'given a seventh chord in first inversion' do
        subject(:set) { HeadMusic::PitchSet.new(%w[E G Bb C5]) }

        it { is_expected.not_to be_triad }
        it { is_expected.to be_seventh_chord }
        it { is_expected.not_to be_root_position_seventh_chord }
        it { is_expected.to be_first_inversion_seventh_chord }
        it { is_expected.not_to be_second_inversion_seventh_chord }
        it { is_expected.not_to be_third_inversion_seventh_chord }
        it { is_expected.to be_tertial }
      end

      context 'given a seventh chord in second inversion' do
        subject(:set) { HeadMusic::PitchSet.new(%w[G Bb C5 E5]) }

        it { is_expected.not_to be_triad }
        it { is_expected.to be_seventh_chord }
        it { is_expected.not_to be_root_position_seventh_chord }
        it { is_expected.not_to be_first_inversion_seventh_chord }
        it { is_expected.to be_second_inversion_seventh_chord }
        it { is_expected.not_to be_third_inversion_seventh_chord }
        it { is_expected.to be_tertial }
      end

      context 'given a seventh chord in third inversion' do
        subject(:set) { HeadMusic::PitchSet.new(%w[Bb C5 E5 G5]) }

        it { is_expected.not_to be_triad }
        it { is_expected.to be_seventh_chord }
        it { is_expected.not_to be_root_position_seventh_chord }
        it { is_expected.not_to be_first_inversion_seventh_chord }
        it { is_expected.not_to be_second_inversion_seventh_chord }
        it { is_expected.to be_third_inversion_seventh_chord }
        it { is_expected.to be_tertial }
      end
    end
  end
end
