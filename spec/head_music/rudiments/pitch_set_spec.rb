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

  describe '#functional_intervals_above_bass_pitch' do
    context 'given a 9th chord' do
      subject(:set) { described_class.new(%w[C E G Bb D5]) }

      specify { expect(set.functional_intervals.map(&:shorthand)).to eq %w[M3 m3 m3 M3] }
      specify { expect(set.functional_intervals_above_bass_pitch.map(&:shorthand)).to eq %w[M3 P5 m7 M9] }
    end
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

      its(:integer_notation) { is_expected.to eq [] }
      its(:scale_degrees) { is_expected.to eq [] }
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

      its(:integer_notation) { is_expected.to eq [0] }
      its(:scale_degrees) { is_expected.to eq [1] }
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

      context 'when the pitches are a major third apart' do
        subject(:set) { HeadMusic::PitchSet.new(%w[D4 F#4]) }

        it { is_expected.to be_tertial }

        its(:integer_notation) { is_expected.to eq [0, 4] }
        its(:scale_degrees) { is_expected.to eq [1, 3] }
      end

      context 'when the pitches are a compound sixth apart' do
        subject(:set) { HeadMusic::PitchSet.new(%w[F#4 D6]) }

        it { is_expected.to be_tertial }

        its(:integer_notation) { is_expected.to eq [0, 8] }
        its(:scale_degrees) { is_expected.to eq [1, 6] }
      end
    end

    context 'when the set has three pitches' do
      context 'given a minor triad' do
        context 'in root position' do
          subject(:set) { HeadMusic::PitchSet.new(%w[D F A]) }

          it { is_expected.to be_triad }
          it { is_expected.to be_consonant_triad }
          it { is_expected.to be_root_position_triad }
          it { is_expected.not_to be_major_triad }
          it { is_expected.to be_minor_triad }
          it { is_expected.to be_tertial }

          its(:integer_notation) { is_expected.to eq [0, 3, 7] }
          its(:scale_degrees) { is_expected.to eq [1, 3, 5] }
        end

        context 'in first inversion' do
          subject(:set) { HeadMusic::PitchSet.new(%w[F A D5]) }

          it { is_expected.to be_triad }
          it { is_expected.to be_consonant_triad }
          it { is_expected.not_to be_root_position_triad }
          it { is_expected.not_to be_major_triad }
          it { is_expected.to be_minor_triad }
          it { is_expected.to be_tertial }

          its(:integer_notation) { is_expected.to eq [0, 4, 9] }
          its(:scale_degrees) { is_expected.to eq [1, 3, 6] }
        end

        context 'in second inversion' do
          subject(:set) { HeadMusic::PitchSet.new(%w[A3 D F]) }

          it { is_expected.to be_triad }
          it { is_expected.to be_consonant_triad }
          it { is_expected.not_to be_root_position_triad }
          it { is_expected.not_to be_major_triad }
          it { is_expected.to be_minor_triad }
          it { is_expected.to be_tertial }

          its(:integer_notation) { is_expected.to eq [0, 5, 8] }
          its(:scale_degrees) { is_expected.to eq [1, 4, 6] }
        end

        context 'spread' do
          subject(:set) { HeadMusic::PitchSet.new(%w[B3 F#4 D5]) }

          it { is_expected.to be_triad }
          it { is_expected.to be_consonant_triad }
          it { is_expected.to be_root_position_triad }
          it { is_expected.not_to be_major_triad }
          it { is_expected.to be_minor_triad }
          it { is_expected.to be_tertial }

          its(:integer_notation) { is_expected.to eq [0, 3, 7] }
          its(:scale_degrees) { is_expected.to eq [1, 3, 5] }
        end

        context 'spread wide' do
          subject(:set) { HeadMusic::PitchSet.new(%w[D3 Bb4 G6]) }

          it { is_expected.to be_triad }
          it { is_expected.to be_consonant_triad }
          it { is_expected.not_to be_root_position_triad }
          it { is_expected.not_to be_major_triad }
          it { is_expected.to be_minor_triad }
          it { is_expected.to be_tertial }

          its(:integer_notation) { is_expected.to eq [0, 5, 8] }
          its(:scale_degrees) { is_expected.to eq [1, 4, 6] }
        end
      end

      context 'given a major triad' do
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

          its(:integer_notation) { is_expected.to eq [0, 4, 7] }
          its(:scale_degrees) { is_expected.to eq [1, 3, 5] }
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

          its(:integer_notation) { is_expected.to eq [0, 3, 8] }
          its(:scale_degrees) { is_expected.to eq [1, 3, 6] }
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

          its(:integer_notation) { is_expected.to eq [0, 5, 9] }
          its(:scale_degrees) { is_expected.to eq [1, 4, 6] }
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

        its(:integer_notation) { is_expected.to eq [0, 3, 6] }
        its(:scale_degrees) { is_expected.to eq [1, 3, 5] }
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

        its(:integer_notation) { is_expected.to eq [0, 4, 8] }
        its(:scale_degrees) { is_expected.to eq [1, 3, 5] }
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
        # implied d7m-m7 (sans 5th) in third inversion
        subject(:set) { HeadMusic::PitchSet.new(%w[C4 D4 F4]) }

        it { is_expected.not_to be_consonant_triad }
        it { is_expected.not_to be_root_position_triad }
        it { is_expected.not_to be_first_inversion_triad }
        it { is_expected.not_to be_second_inversion_triad }
        it { is_expected.not_to be_major_triad }
        it { is_expected.not_to be_minor_triad }
        it { is_expected.not_to be_tertial }

        its(:integer_notation) { is_expected.to eq [0, 2, 5] }
        its(:scale_degrees) { is_expected.to eq [1, 2, 4] }
      end
    end

    context 'when the set has four pitches' do
      context 'given a major-minor seventh chord in root position' do
        subject(:set) { HeadMusic::PitchSet.new(%w[C E G Bb]) }

        it { is_expected.not_to be_triad }
        it { is_expected.to be_seventh_chord }
        it { is_expected.to be_root_position_seventh_chord }
        it { is_expected.not_to be_first_inversion_seventh_chord }
        it { is_expected.not_to be_second_inversion_seventh_chord }
        it { is_expected.not_to be_third_inversion_seventh_chord }
        it { is_expected.to be_tertial }
      end

      context 'given a major-minor seventh chord in first inversion' do
        subject(:set) { HeadMusic::PitchSet.new(%w[E G Bb C5]) }

        it { is_expected.not_to be_triad }
        it { is_expected.to be_seventh_chord }
        it { is_expected.not_to be_root_position_seventh_chord }
        it { is_expected.to be_first_inversion_seventh_chord }
        it { is_expected.not_to be_second_inversion_seventh_chord }
        it { is_expected.not_to be_third_inversion_seventh_chord }
        it { is_expected.to be_tertial }
      end

      context 'given a major-minor seventh chord in second inversion' do
        subject(:set) { HeadMusic::PitchSet.new(%w[G Bb C5 E5]) }

        it { is_expected.not_to be_triad }
        it { is_expected.to be_seventh_chord }
        it { is_expected.not_to be_root_position_seventh_chord }
        it { is_expected.not_to be_first_inversion_seventh_chord }
        it { is_expected.to be_second_inversion_seventh_chord }
        it { is_expected.not_to be_third_inversion_seventh_chord }
        it { is_expected.to be_tertial }
      end

      context 'given a major-minor seventh chord in third inversion' do
        subject(:set) { HeadMusic::PitchSet.new(%w[Bb C5 E5 G5]) }

        it { is_expected.not_to be_triad }
        it { is_expected.to be_seventh_chord }
        it { is_expected.not_to be_root_position_seventh_chord }
        it { is_expected.not_to be_first_inversion_seventh_chord }
        it { is_expected.not_to be_second_inversion_seventh_chord }
        it { is_expected.to be_third_inversion_seventh_chord }
        it { is_expected.to be_tertial }
        it { is_expected.not_to be_ninth_chord }
        it { is_expected.not_to be_eleventh_chord }
        it { is_expected.not_to be_thirteenth_chord }

        its(:integer_notation) { is_expected.to eq [0, 2, 6, 9] }
        its(:scale_degrees) { is_expected.to eq [1, 2, 4, 6] }
      end
    end

    context 'when the set has five pitches' do
      context 'given a ninth chord in root position' do
        subject(:set) { HeadMusic::PitchSet.new(%w[C E G Bb D5]) }

        it { is_expected.not_to be_triad }
        it { is_expected.not_to be_seventh_chord }
        it { is_expected.to be_ninth_chord }
        it { is_expected.to be_tertial }
        it { is_expected.not_to be_eleventh_chord }
        it { is_expected.not_to be_thirteenth_chord }
      end

      context 'given a spread ninth chord with the 7th in the bass' do
        subject(:set) { HeadMusic::PitchSet.new(%w[Bb2 D4 G4 C5 E5]) }

        it { is_expected.not_to be_triad }
        it { is_expected.not_to be_seventh_chord }
        it { is_expected.to be_ninth_chord }
        it { is_expected.to be_tertial }
        it { is_expected.not_to be_eleventh_chord }
        it { is_expected.not_to be_thirteenth_chord }

        its(:integer_notation) { is_expected.to eq [0, 2, 4, 6, 9] }
        its(:scale_degrees) { is_expected.to eq [1, 2, 3, 4, 6] }
      end
    end

    context 'when the set has six pitch classes with six different letter names' do
      context 'given an eleventh chord cluster' do
        subject(:set) { HeadMusic::PitchSet.new(%w[G3 Bb3 C D E F G]) }

        it { is_expected.to be_tertial }
        it { is_expected.not_to be_triad }
        it { is_expected.not_to be_seventh_chord }
        it { is_expected.not_to be_ninth_chord }
        it { is_expected.to be_eleventh_chord }
        it { is_expected.not_to be_thirteenth_chord }
      end
    end

    context 'when the set has seven pitch classes with seven different letter names' do
      context 'given an eleventh chord cluster' do
        subject(:set) { HeadMusic::PitchSet.new(%w[G3 Bb3 C D E F G A]) }

        it { is_expected.to be_tertial }
        it { is_expected.not_to be_triad }
        it { is_expected.not_to be_seventh_chord }
        it { is_expected.not_to be_ninth_chord }
        it { is_expected.not_to be_eleventh_chord }
        it { is_expected.to be_thirteenth_chord }
      end
    end

    context 'when the set has eight pitch classes with seven different letter names' do
      context 'given an eleventh chord cluster' do
        subject(:set) { HeadMusic::PitchSet.new(%w[G3 Bb3 C D E F G# A]) }

        it { is_expected.not_to be_triad }
        it { is_expected.not_to be_seventh_chord }
        it { is_expected.not_to be_ninth_chord }
        it { is_expected.not_to be_eleventh_chord }
        it { is_expected.not_to be_thirteenth_chord }

        its(:integer_notation) { is_expected.to eq [0, 1, 2, 3, 5, 7, 9, 10] }
        its(:scale_degrees) { is_expected.to eq [1, 2, 3, 4, 5, 6, 7] }
      end
    end
  end
end
