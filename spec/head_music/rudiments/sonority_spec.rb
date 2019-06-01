# frozen_string_literal: true

require 'spec_helper'

describe HeadMusic::Analysis::Sonority do
  describe 'equality' do
    subject(:sonority) { described_class.for(pitch_set) }

    context 'given a major triad' do
      let(:pitch_set) { HeadMusic::PitchSet.new(%w[G4 B4 D5]) }

      it { is_expected.not_to be_nil }

      context 'compared to another sonority with a pitch set with the same pitches' do
        let(:other_pitch_set) { HeadMusic::PitchSet.new(%w[G4 B4 D5]) }
        let(:other_sonority) { described_class.for(other_pitch_set) }

        it { is_expected.to eq other_sonority }
      end

      context 'compared to a pitch set with the same pitches' do
        let(:other_pitch_set) { HeadMusic::PitchSet.new(%w[G4 B4 D5]) }

        it { is_expected.to eq other_pitch_set }
      end

      context 'compared to another sonority with a different dominant seventh chord pitch set' do
        let(:other_pitch_set) { HeadMusic::PitchSet.new(%w[C E G]) }
        let(:other_sonority) { described_class.for(other_pitch_set) }

        it { is_expected.to eq other_sonority }
      end
    end
  end

  describe '.for' do
    subject(:sonority) { described_class.for(pitch_set) }

    context 'when given a simple dyad' do
      let(:pitch_set) { HeadMusic::PitchSet.new(%w[C G]) }

      it { is_expected.to be_nil }
    end

    context 'when given a major triad in root position' do
      let(:pitch_set) { HeadMusic::PitchSet.new(%w[C E G]) }

      it { is_expected.to be_a(HeadMusic::Analysis::MajorTriad) }
      it { is_expected.to be_trichord }
      it { is_expected.to be_triad }
      it { is_expected.to be_tertian }

      its(:inversion) { is_expected.to eq 0 }
    end

    context 'when given a major triad in first inversion' do
      let(:pitch_set) { HeadMusic::PitchSet.new(%w[E G C5]) }

      it { is_expected.to be_a(HeadMusic::Analysis::MajorTriad) }
      it { is_expected.to be_triad }
      it { is_expected.to be_trichord }
      it { is_expected.to be_tertian }

      its(:inversion) { is_expected.to eq 1 }
    end

    context 'when given a major triad in second inversion' do
      let(:pitch_set) { HeadMusic::PitchSet.new(%w[G3 C E]) }

      it { is_expected.to be_a(HeadMusic::Analysis::MajorTriad) }
      it { is_expected.to be_triad }
      it { is_expected.to be_trichord }
      it { is_expected.to be_tertian }

      its(:inversion) { is_expected.to eq 2 }
    end

    context 'when given a minor triad in root position' do
      let(:pitch_set) { HeadMusic::PitchSet.new(%w[C Eb G]) }

      it { is_expected.to be_a(HeadMusic::Analysis::MinorTriad) }
      it { is_expected.to be_trichord }
      it { is_expected.to be_triad }
      it { is_expected.to be_tertian }

      its(:inversion) { is_expected.to eq 0 }
    end

    context 'when given a minor triad in first inversion' do
      let(:pitch_set) { HeadMusic::PitchSet.new(%w[Eb G C5]) }

      it { is_expected.to be_a(HeadMusic::Analysis::MinorTriad) }
      it { is_expected.to be_triad }
      it { is_expected.to be_trichord }
      it { is_expected.to be_tertian }

      its(:inversion) { is_expected.to eq 1 }
    end

    context 'when given a minor triad in second inversion' do
      let(:pitch_set) { HeadMusic::PitchSet.new(%w[G3 C Eb]) }

      it { is_expected.to be_a(HeadMusic::Analysis::MinorTriad) }
      it { is_expected.to be_triad }
      it { is_expected.to be_trichord }
      it { is_expected.to be_tertian }

      its(:inversion) { is_expected.to eq 2 }
    end

    context 'when given a diminished triad in root position' do
      let(:pitch_set) { HeadMusic::PitchSet.new(%w[C Eb Gb]) }

      it { is_expected.to be_a(HeadMusic::Analysis::DiminishedTriad) }
      it { is_expected.to be_trichord }
      it { is_expected.to be_triad }
      it { is_expected.not_to be_consonant }
      it { is_expected.to be_tertian }

      its(:inversion) { is_expected.to eq 0 }
    end

    context 'when given a diminished triad in first inversion' do
      let(:pitch_set) { HeadMusic::PitchSet.new(%w[Eb Gb C5]) }

      it { is_expected.to be_a(HeadMusic::Analysis::DiminishedTriad) }
      it { is_expected.to be_triad }
      it { is_expected.to be_trichord }
      it { is_expected.not_to be_consonant }
      it { is_expected.to be_tertian }

      its(:inversion) { is_expected.to eq 1 }
    end

    context 'when given an diminished triad in second inversion' do
      let(:pitch_set) { HeadMusic::PitchSet.new(%w[Gb3 C Eb]) }

      it { is_expected.to be_a(HeadMusic::Analysis::DiminishedTriad) }
      it { is_expected.to be_triad }
      it { is_expected.to be_trichord }
      it { is_expected.not_to be_consonant }
      it { is_expected.to be_tertian }

      its(:inversion) { is_expected.to eq 2 }
    end

    context 'when given an augmented triad in root position' do
      let(:pitch_set) { HeadMusic::PitchSet.new(%w[C E G#]) }

      it { is_expected.to be_a(HeadMusic::Analysis::AugmentedTriad) }
      it { is_expected.to be_trichord }
      it { is_expected.to be_triad }
      it { is_expected.not_to be_consonant }
      it { is_expected.to be_tertian }

      its(:inversion) { is_expected.to eq 0 }
    end

    context 'when given an augmented triad in first inversion' do
      let(:pitch_set) { HeadMusic::PitchSet.new(%w[E G# C5]) }

      it { is_expected.to be_a(HeadMusic::Analysis::AugmentedTriad) }
      it { is_expected.to be_triad }
      it { is_expected.to be_trichord }
      it { is_expected.not_to be_consonant }
      it { is_expected.to be_tertian }

      its(:inversion) { is_expected.to eq 0 }
    end

    context 'when given an augmented triad in second inversion' do
      let(:pitch_set) { HeadMusic::PitchSet.new(%w[G#3 C E]) }

      it { is_expected.to be_a(HeadMusic::Analysis::AugmentedTriad) }
      it { is_expected.to be_triad }
      it { is_expected.to be_trichord }
      it { is_expected.not_to be_consonant }
      it { is_expected.to be_tertian }

      its(:inversion) { is_expected.to eq 0 }
    end

    context 'when given a dominant seventh chord' do
      context 'when in root position' do
        let(:pitch_set) { HeadMusic::PitchSet.new(%w[G3 B3 D F]) }

        it { is_expected.to be_a(HeadMusic::Analysis::MajorMinorSeventhChord) }
        it { is_expected.to be_seventh_chord }
        it { is_expected.to be_tetrachord }
        it { is_expected.not_to be_consonant }
        it { is_expected.to be_tertian }
      end

      context 'when in first inversion' do
        let(:pitch_set) { HeadMusic::PitchSet.new(%w[B3 D F G]) }

        it { is_expected.to be_a(HeadMusic::Analysis::MajorMinorSeventhChord) }
        it { is_expected.to be_seventh_chord }
        it { is_expected.to be_tetrachord }
        it { is_expected.not_to be_consonant }
        it { is_expected.to be_tertian }
      end

      context 'when in second inversion' do
        let(:pitch_set) { HeadMusic::PitchSet.new(%w[D F G B]) }

        it { is_expected.to be_a(HeadMusic::Analysis::MajorMinorSeventhChord) }
        it { is_expected.to be_seventh_chord }
        it { is_expected.to be_tetrachord }
        it { is_expected.not_to be_consonant }
        it { is_expected.to be_tertian }
      end

      context 'when in third inversion' do
        let(:pitch_set) { HeadMusic::PitchSet.new(%w[F G B D5]) }

        it { is_expected.to be_a(HeadMusic::Analysis::MajorMinorSeventhChord) }
        it { is_expected.to be_seventh_chord }
        it { is_expected.to be_tetrachord }
        it { is_expected.not_to be_consonant }
        it { is_expected.to be_tertian }
      end
    end

    context 'when given a major-major seventh chord' do
      context 'when in root position' do
        let(:pitch_set) { HeadMusic::PitchSet.new(%w[G3 B3 D F#]) }

        it { is_expected.to be_a(HeadMusic::Analysis::MajorMajorSeventhChord) }
        it { is_expected.to be_seventh_chord }
        it { is_expected.to be_tetrachord }
        it { is_expected.not_to be_consonant }
        it { is_expected.to be_tertian }
      end

      context 'when in first inversion' do
        let(:pitch_set) { HeadMusic::PitchSet.new(%w[B3 D F# G]) }

        it { is_expected.to be_a(HeadMusic::Analysis::MajorMajorSeventhChord) }
        it { is_expected.to be_seventh_chord }
        it { is_expected.to be_tetrachord }
        it { is_expected.not_to be_consonant }
        it { is_expected.to be_tertian }
      end

      context 'when in second inversion' do
        let(:pitch_set) { HeadMusic::PitchSet.new(%w[D F# G B]) }

        it { is_expected.to be_a(HeadMusic::Analysis::MajorMajorSeventhChord) }
        it { is_expected.to be_seventh_chord }
        it { is_expected.to be_tetrachord }
        it { is_expected.not_to be_consonant }
        it { is_expected.to be_tertian }
      end

      context 'when in third inversion' do
        let(:pitch_set) { HeadMusic::PitchSet.new(%w[F# G B D5]) }

        it { is_expected.to be_a(HeadMusic::Analysis::MajorMajorSeventhChord) }
        it { is_expected.to be_seventh_chord }
        it { is_expected.to be_tetrachord }
        it { is_expected.not_to be_consonant }
        it { is_expected.to be_tertian }
      end
    end

    context 'when given a minor seventh chord' do
      context 'when in root position' do
        let(:pitch_set) { HeadMusic::PitchSet.new(%w[G3 Bb3 D F]) }

        it { is_expected.to be_a(HeadMusic::Analysis::MinorMinorSeventhChord) }
        it { is_expected.to be_seventh_chord }
        it { is_expected.to be_tetrachord }
        it { is_expected.not_to be_consonant }
        it { is_expected.to be_tertian }
      end

      context 'when in first inversion' do
        let(:pitch_set) { HeadMusic::PitchSet.new(%w[Bb3 D F G]) }

        it { is_expected.to be_a(HeadMusic::Analysis::MinorMinorSeventhChord) }
        it { is_expected.to be_seventh_chord }
        it { is_expected.to be_tetrachord }
        it { is_expected.not_to be_consonant }
        it { is_expected.to be_tertian }
      end

      context 'when in second inversion' do
        let(:pitch_set) { HeadMusic::PitchSet.new(%w[D F G Bb]) }

        it { is_expected.to be_a(HeadMusic::Analysis::MinorMinorSeventhChord) }
        it { is_expected.to be_seventh_chord }
        it { is_expected.to be_tetrachord }
        it { is_expected.not_to be_consonant }
        it { is_expected.to be_tertian }
      end

      context 'when in third inversion' do
        let(:pitch_set) { HeadMusic::PitchSet.new(%w[F G Bb D5]) }

        it { is_expected.to be_a(HeadMusic::Analysis::MinorMinorSeventhChord) }
        it { is_expected.to be_seventh_chord }
        it { is_expected.to be_tetrachord }
        it { is_expected.not_to be_consonant }
        it { is_expected.to be_tertian }
      end
    end

    context 'when given a minor-major seventh chord' do
      context 'when in root position' do
        let(:pitch_set) { HeadMusic::PitchSet.new(%w[G3 Bb3 D F#]) }

        it { is_expected.to be_a(HeadMusic::Analysis::MinorMajorSeventhChord) }
        it { is_expected.to be_seventh_chord }
        it { is_expected.to be_tetrachord }
        it { is_expected.not_to be_consonant }
        it { is_expected.to be_tertian }
      end

      context 'when in first inversion' do
        let(:pitch_set) { HeadMusic::PitchSet.new(%w[Bb3 D F# G]) }

        it { is_expected.to be_a(HeadMusic::Analysis::MinorMajorSeventhChord) }
        it { is_expected.to be_seventh_chord }
        it { is_expected.to be_tetrachord }
        it { is_expected.not_to be_consonant }
        it { is_expected.to be_tertian }
      end

      context 'when in second inversion' do
        let(:pitch_set) { HeadMusic::PitchSet.new(%w[D F# G Bb]) }

        it { is_expected.to be_a(HeadMusic::Analysis::MinorMajorSeventhChord) }
        it { is_expected.to be_seventh_chord }
        it { is_expected.to be_tetrachord }
        it { is_expected.not_to be_consonant }
        it { is_expected.to be_tertian }
      end

      context 'when in third inversion' do
        let(:pitch_set) { HeadMusic::PitchSet.new(%w[F# G Bb D5]) }

        it { is_expected.to be_a(HeadMusic::Analysis::MinorMajorSeventhChord) }
        it { is_expected.to be_seventh_chord }
        it { is_expected.to be_tetrachord }
        it { is_expected.not_to be_consonant }
        it { is_expected.to be_tertian }
      end
    end
  end
end
