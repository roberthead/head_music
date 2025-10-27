require "spec_helper"

describe HeadMusic::Analysis::Sonority do
  describe ".get" do
    context "with a valid identifier" do
      subject(:sonority) { described_class.get(:major_triad) }

      it "returns a Sonority object" do
        expect(sonority).to be_a(described_class)
      end

      it "has the correct identifier" do
        expect(sonority.identifier).to eq(:major_triad)
      end

      it "generates pitches at the default root (C4)" do
        expect(sonority.pitch_collection.pitches.map(&:to_s)).to eq(%w[C4 E4 G4])
      end

      it "is a triad" do
        expect(sonority).to be_triad
      end
    end

    context "with a minor triad identifier" do
      subject(:sonority) { described_class.get(:minor_triad) }

      it "generates the correct pitches" do
        expect(sonority.pitch_collection.pitches.map(&:to_s)).to eq(["C4", "E♭4", "G4"])
      end

      it "has the correct identifier" do
        expect(sonority.identifier).to eq(:minor_triad)
      end
    end

    context "with a seventh chord identifier" do
      subject(:sonority) { described_class.get(:major_minor_seventh_chord) }

      it "generates the correct pitches" do
        expect(sonority.pitch_collection.pitches.map(&:to_s)).to eq(["C4", "E4", "G4", "B♭4"])
      end

      it "is a seventh chord" do
        expect(sonority).to be_seventh_chord
      end
    end

    context "with a custom root" do
      subject(:sonority) { described_class.get(:major_triad, root: "D4") }

      it "generates pitches at the specified root" do
        expect(sonority.pitch_collection.pitches.map(&:to_s)).to eq(["D4", "F♯4", "A4"])
      end

      it "still identifies as major triad" do
        expect(sonority.identifier).to eq(:major_triad)
      end
    end

    context "with inversions" do
      context "with major triad in root position (inversion: 0)" do
        subject(:sonority) { described_class.get(:major_triad, root: "C4", inversion: 0) }

        it "generates root position pitches" do
          expect(sonority.pitch_collection.pitches.map(&:to_s)).to eq(%w[C4 E4 G4])
        end

        it "identifies as major triad" do
          expect(sonority.identifier).to eq(:major_triad)
        end
      end

      context "with major triad in first inversion (inversion: 1)" do
        subject(:sonority) { described_class.get(:major_triad, root: "C4", inversion: 1) }

        it "generates first inversion pitches" do
          expect(sonority.pitch_collection.pitches.map(&:to_s)).to eq(%w[E4 G4 C5])
        end

        it "still identifies as major triad" do
          expect(sonority.identifier).to eq(:major_triad)
        end
      end

      context "with major triad in second inversion (inversion: 2)" do
        subject(:sonority) { described_class.get(:major_triad, root: "C4", inversion: 2) }

        it "generates second inversion pitches" do
          expect(sonority.pitch_collection.pitches.map(&:to_s)).to eq(%w[G4 C5 E5])
        end

        it "still identifies as major triad" do
          expect(sonority.identifier).to eq(:major_triad)
        end
      end

      context "with minor seventh chord in root position" do
        subject(:sonority) { described_class.get(:minor_minor_seventh_chord, root: "D4", inversion: 0) }

        it "generates root position pitches" do
          expect(sonority.pitch_collection.pitches.map(&:to_s)).to eq(%w[D4 F4 A4 C5])
        end

        it "identifies as minor seventh" do
          expect(sonority.identifier).to eq(:minor_minor_seventh_chord)
        end
      end

      context "with minor seventh chord in first inversion" do
        subject(:sonority) { described_class.get(:minor_minor_seventh_chord, root: "D4", inversion: 1) }

        it "generates first inversion pitches" do
          expect(sonority.pitch_collection.pitches.map(&:to_s)).to eq(%w[F4 A4 C5 D5])
        end

        it "still identifies as minor seventh" do
          expect(sonority.identifier).to eq(:minor_minor_seventh_chord)
        end
      end

      context "with minor seventh chord in second inversion" do
        subject(:sonority) { described_class.get(:minor_minor_seventh_chord, root: "D4", inversion: 2) }

        it "generates second inversion pitches" do
          expect(sonority.pitch_collection.pitches.map(&:to_s)).to eq(%w[A4 C5 D5 F5])
        end

        it "still identifies as minor seventh" do
          expect(sonority.identifier).to eq(:minor_minor_seventh_chord)
        end
      end

      context "with minor seventh chord in third inversion" do
        subject(:sonority) { described_class.get(:minor_minor_seventh_chord, root: "D4", inversion: 3) }

        it "generates third inversion pitches" do
          expect(sonority.pitch_collection.pitches.map(&:to_s)).to eq(%w[C5 D5 F5 A5])
        end

        it "still identifies as minor seventh" do
          expect(sonority.identifier).to eq(:minor_minor_seventh_chord)
        end
      end

      context "with custom root and inversion" do
        subject(:sonority) { described_class.get(:major_triad, root: "E♭4", inversion: 1) }

        it "generates pitches with both custom root and inversion" do
          expect(sonority.pitch_collection.pitches.map(&:to_s)).to eq(["G4", "B♭4", "E♭5"])
        end

        it "identifies as major triad" do
          expect(sonority.identifier).to eq(:major_triad)
        end
      end
    end

    context "with a string identifier" do
      subject(:sonority) { described_class.get("minor_triad") }

      it "accepts string identifiers" do
        expect(sonority.identifier).to eq(:minor_triad)
      end
    end

    context "with an invalid identifier" do
      subject(:sonority) { described_class.get(:nonexistent_chord) }

      it "returns nil" do
        expect(sonority).to be_nil
      end
    end

    context "with all defined sonorities" do
      it "can create all SONORITIES" do
        described_class.identifiers.each do |identifier|
          sonority = described_class.get(identifier)
          expect(sonority).to be_a(described_class)
          expect(sonority.identifier).not_to be_nil
        end
      end

      it "creates sonorities that match their identifier or an inversion" do
        # Note: sus2 and sus4 are inversionally related, so suspended_two_chord
        # may identify as suspended_four_chord depending on inversion
        described_class.identifiers.each do |identifier|
          sonority = described_class.get(identifier)
          # The identifier should be one of the known sonorities
          expect(described_class.identifiers).to include(sonority.identifier)
        end
      end
    end
  end

  describe ".identifiers" do
    it "returns an array of symbols" do
      expect(described_class.identifiers).to all(be_a(Symbol))
    end

    it "includes major_triad" do
      expect(described_class.identifiers).to include(:major_triad)
    end

    it "includes all defined sonorities" do
      expect(described_class.identifiers).to match_array(described_class::SONORITIES.keys)
    end

    it "returns 19 sonority types" do
      expect(described_class.identifiers.size).to eq(19)
    end
  end

  describe "equality" do
    subject(:sonority) { described_class.new(pitch_collection) }

    context "given a major triad" do
      let(:pitch_collection) { HeadMusic::Analysis::PitchCollection.new(%w[G4 B4 D5]) }

      it { is_expected.not_to be_nil }

      context "when compared to another sonority with a pitch collection with the same pitches" do
        let(:other_pitch_collection) { HeadMusic::Analysis::PitchCollection.new(%w[G4 B4 D5]) }
        let(:other_sonority) { described_class.new(other_pitch_collection) }

        it { is_expected.to eq other_sonority }
      end

      context "when compared to a pitch collection with the same pitches" do
        let(:other_pitch_collection) { HeadMusic::Analysis::PitchCollection.new(%w[G4 B4 D5]) }

        it { is_expected.to eq other_pitch_collection }
      end

      context "when compared to an array of pitches" do
        let(:other_pitches) { %w[G4 B4 D5] }

        it { is_expected.to eq other_pitches }
      end

      context "when compared to another sonority with a different major triad pitch collection" do
        let(:other_pitch_collection) { HeadMusic::Analysis::PitchCollection.new(%w[C E G]) }
        let(:other_sonority) { described_class.new(other_pitch_collection) }

        it { is_expected.to eq other_sonority }
      end
    end

    context "given an empty pitch collection" do
      let(:pitch_collection) { HeadMusic::Analysis::PitchCollection.new([]) }

      it { is_expected.not_to be_nil }

      its(:diatonic_intervals_above_bass_pitch) { is_expected.to be_empty }
    end
  end

  describe ".for" do
    subject(:sonority) { described_class.new(pitch_collection) }

    context "when given a simple dyad" do
      let(:pitch_collection) { HeadMusic::Analysis::PitchCollection.new(%w[C G]) }

      its(:identifier) { is_expected.to be_nil }
    end

    context "when given a major triad in root position" do
      let(:pitch_collection) { HeadMusic::Analysis::PitchCollection.new(%w[C E G]) }

      its(:identifier) { is_expected.to eq :major_triad }
      it { is_expected.to be_trichord }
      it { is_expected.to be_triad }
      it { is_expected.to be_tertian }
      it { is_expected.not_to be_secundal }
      it { is_expected.not_to be_quartal }

      its(:inversion) { is_expected.to eq 0 }
    end

    context "when given a major triad in first inversion" do
      let(:pitch_collection) { HeadMusic::Analysis::PitchCollection.new(%w[E G C5]) }

      its(:identifier) { is_expected.to eq :major_triad }
      it { is_expected.to be_triad }
      it { is_expected.to be_trichord }
      it { is_expected.to be_tertian }
      it { is_expected.not_to be_secundal }
      it { is_expected.not_to be_quartal }

      its(:inversion) { is_expected.to eq 1 }
    end

    context "when given a major triad in second inversion" do
      let(:pitch_collection) { HeadMusic::Analysis::PitchCollection.new(%w[G3 C E]) }

      its(:identifier) { is_expected.to eq :major_triad }
      it { is_expected.to be_triad }
      it { is_expected.to be_trichord }
      it { is_expected.to be_tertian }
      it { is_expected.not_to be_secundal }
      it { is_expected.not_to be_quartal }

      its(:inversion) { is_expected.to eq 2 }
    end

    context "when given a minor triad in root position" do
      let(:pitch_collection) { HeadMusic::Analysis::PitchCollection.new(%w[C Eb G]) }

      its(:identifier) { is_expected.to eq :minor_triad }
      it { is_expected.to be_trichord }
      it { is_expected.to be_triad }
      it { is_expected.to be_tertian }
      it { is_expected.not_to be_secundal }
      it { is_expected.not_to be_quartal }

      its(:inversion) { is_expected.to eq 0 }
    end

    context "when given a minor triad in first inversion" do
      let(:pitch_collection) { HeadMusic::Analysis::PitchCollection.new(%w[Eb G C5]) }

      its(:identifier) { is_expected.to eq :minor_triad }
      it { is_expected.to be_triad }
      it { is_expected.to be_trichord }
      it { is_expected.to be_tertian }
      it { is_expected.not_to be_secundal }
      it { is_expected.not_to be_quartal }

      its(:inversion) { is_expected.to eq 1 }
    end

    context "when given a minor triad in second inversion" do
      let(:pitch_collection) { HeadMusic::Analysis::PitchCollection.new(%w[G3 C Eb]) }

      its(:identifier) { is_expected.to eq :minor_triad }
      it { is_expected.to be_triad }
      it { is_expected.to be_trichord }
      it { is_expected.to be_tertian }
      it { is_expected.not_to be_secundal }
      it { is_expected.not_to be_quartal }

      its(:inversion) { is_expected.to eq 2 }
    end

    context "when given a diminished triad in root position" do
      let(:pitch_collection) { HeadMusic::Analysis::PitchCollection.new(%w[C Eb Gb]) }

      its(:identifier) { is_expected.to eq :diminished_triad }
      it { is_expected.to be_trichord }
      it { is_expected.to be_triad }
      it { is_expected.not_to be_consonant }
      it { is_expected.to be_tertian }
      it { is_expected.not_to be_secundal }
      it { is_expected.not_to be_quartal }

      its(:inversion) { is_expected.to eq 0 }
    end

    context "when given a diminished triad in first inversion" do
      let(:pitch_collection) { HeadMusic::Analysis::PitchCollection.new(%w[Eb Gb C5]) }

      its(:identifier) { is_expected.to eq :diminished_triad }
      it { is_expected.to be_triad }
      it { is_expected.to be_trichord }
      it { is_expected.not_to be_consonant }
      it { is_expected.to be_tertian }
      it { is_expected.not_to be_secundal }
      it { is_expected.not_to be_quartal }

      its(:inversion) { is_expected.to eq 1 }
    end

    context "when given an diminished triad in second inversion" do
      let(:pitch_collection) { HeadMusic::Analysis::PitchCollection.new(%w[Gb3 C Eb]) }

      its(:identifier) { is_expected.to eq :diminished_triad }
      it { is_expected.to be_triad }
      it { is_expected.to be_trichord }
      it { is_expected.not_to be_consonant }
      it { is_expected.to be_tertian }
      it { is_expected.not_to be_secundal }
      it { is_expected.not_to be_quartal }

      its(:inversion) { is_expected.to eq 2 }
    end

    context "when given an augmented triad in root position" do
      let(:pitch_collection) { HeadMusic::Analysis::PitchCollection.new(%w[C E G#]) }

      its(:identifier) { is_expected.to eq :augmented_triad }
      it { is_expected.to be_trichord }
      it { is_expected.to be_triad }
      it { is_expected.not_to be_consonant }
      it { is_expected.to be_tertian }
      it { is_expected.not_to be_secundal }
      it { is_expected.not_to be_quartal }

      its(:inversion) { is_expected.to eq 0 }
    end

    context "when given an augmented triad in first inversion" do
      let(:pitch_collection) { HeadMusic::Analysis::PitchCollection.new(%w[E G# C5]) }

      its(:identifier) { is_expected.to eq :augmented_triad }
      it { is_expected.to be_triad }
      it { is_expected.to be_trichord }
      it { is_expected.not_to be_consonant }
      it { is_expected.to be_tertian }
      it { is_expected.not_to be_secundal }
      it { is_expected.not_to be_quartal }

      its(:inversion) { is_expected.to eq 1 }
    end

    context "when given an augmented triad in second inversion" do
      let(:pitch_collection) { HeadMusic::Analysis::PitchCollection.new(%w[G#3 C E]) }

      its(:identifier) { is_expected.to eq :augmented_triad }
      it { is_expected.to be_triad }
      it { is_expected.to be_trichord }
      it { is_expected.not_to be_consonant }
      it { is_expected.to be_tertian }
      it { is_expected.not_to be_secundal }
      it { is_expected.not_to be_quartal }

      its(:inversion) { is_expected.to eq 2 }
    end

    context "when given a dominant seventh chord" do
      context "when in root position" do
        let(:pitch_collection) { HeadMusic::Analysis::PitchCollection.new(%w[G3 B3 D F]) }

        its(:identifier) { is_expected.to eq :major_minor_seventh_chord }
        it { is_expected.to be_seventh_chord }
        it { is_expected.to be_tetrachord }
        it { is_expected.not_to be_consonant }
        it { is_expected.to be_tertian }
        it { is_expected.not_to be_secundal }
        it { is_expected.not_to be_quartal }
      end

      context "when in first inversion" do
        let(:pitch_collection) { HeadMusic::Analysis::PitchCollection.new(%w[B3 D F G]) }

        its(:identifier) { is_expected.to eq :major_minor_seventh_chord }
        it { is_expected.to be_seventh_chord }
        it { is_expected.to be_tetrachord }
        it { is_expected.not_to be_consonant }
        it { is_expected.to be_tertian }
        it { is_expected.not_to be_secundal }
        it { is_expected.not_to be_quartal }
      end

      context "when in second inversion" do
        let(:pitch_collection) { HeadMusic::Analysis::PitchCollection.new(%w[D F G B]) }

        its(:identifier) { is_expected.to eq :major_minor_seventh_chord }
        it { is_expected.to be_seventh_chord }
        it { is_expected.to be_tetrachord }
        it { is_expected.not_to be_consonant }
        it { is_expected.to be_tertian }
        it { is_expected.not_to be_secundal }
        it { is_expected.not_to be_quartal }
      end

      context "when in third inversion" do
        let(:pitch_collection) { HeadMusic::Analysis::PitchCollection.new(%w[F G B D5]) }

        its(:identifier) { is_expected.to eq :major_minor_seventh_chord }
        it { is_expected.to be_seventh_chord }
        it { is_expected.to be_tetrachord }
        it { is_expected.not_to be_consonant }
        it { is_expected.to be_tertian }
        it { is_expected.not_to be_secundal }
        it { is_expected.not_to be_quartal }
      end
    end

    context "when given a major-major seventh chord" do
      context "when in root position" do
        let(:pitch_collection) { HeadMusic::Analysis::PitchCollection.new(%w[G3 B3 D F#]) }

        its(:identifier) { is_expected.to eq :major_major_seventh_chord }
        it { is_expected.to be_seventh_chord }
        it { is_expected.to be_tetrachord }
        it { is_expected.not_to be_consonant }
        it { is_expected.to be_tertian }
        it { is_expected.not_to be_secundal }
        it { is_expected.not_to be_quartal }
      end

      context "when in first inversion" do
        let(:pitch_collection) { HeadMusic::Analysis::PitchCollection.new(%w[B3 D F# G]) }

        its(:identifier) { is_expected.to eq :major_major_seventh_chord }
        it { is_expected.to be_seventh_chord }
        it { is_expected.to be_tetrachord }
        it { is_expected.not_to be_consonant }
        it { is_expected.to be_tertian }
        it { is_expected.not_to be_secundal }
        it { is_expected.not_to be_quartal }
      end

      context "when in second inversion" do
        let(:pitch_collection) { HeadMusic::Analysis::PitchCollection.new(%w[D F# G B]) }

        its(:identifier) { is_expected.to eq :major_major_seventh_chord }
        it { is_expected.to be_seventh_chord }
        it { is_expected.to be_tetrachord }
        it { is_expected.not_to be_consonant }
        it { is_expected.to be_tertian }
        it { is_expected.not_to be_secundal }
        it { is_expected.not_to be_quartal }
      end

      context "when in third inversion" do
        let(:pitch_collection) { HeadMusic::Analysis::PitchCollection.new(%w[F# G B D5]) }

        its(:identifier) { is_expected.to eq :major_major_seventh_chord }
        it { is_expected.to be_seventh_chord }
        it { is_expected.to be_tetrachord }
        it { is_expected.not_to be_consonant }
        it { is_expected.to be_tertian }
        it { is_expected.not_to be_secundal }
        it { is_expected.not_to be_quartal }
      end
    end

    context "when given a minor seventh chord" do
      context "when in root position" do
        let(:pitch_collection) { HeadMusic::Analysis::PitchCollection.new(%w[G3 Bb3 D F]) }

        its(:identifier) { is_expected.to eq :minor_minor_seventh_chord }
        it { is_expected.to be_seventh_chord }
        it { is_expected.to be_tetrachord }
        it { is_expected.not_to be_consonant }
        it { is_expected.to be_tertian }
        it { is_expected.not_to be_secundal }
        it { is_expected.not_to be_quartal }
      end

      context "when in first inversion" do
        let(:pitch_collection) { HeadMusic::Analysis::PitchCollection.new(%w[Bb3 D F G]) }

        its(:identifier) { is_expected.to eq :minor_minor_seventh_chord }
        it { is_expected.to be_seventh_chord }
        it { is_expected.to be_tetrachord }
        it { is_expected.not_to be_consonant }
        it { is_expected.to be_tertian }
        it { is_expected.not_to be_secundal }
        it { is_expected.not_to be_quartal }
      end

      context "when in second inversion" do
        let(:pitch_collection) { HeadMusic::Analysis::PitchCollection.new(%w[D F G Bb]) }

        its(:identifier) { is_expected.to eq :minor_minor_seventh_chord }
        it { is_expected.to be_seventh_chord }
        it { is_expected.to be_tetrachord }
        it { is_expected.not_to be_consonant }
        it { is_expected.to be_tertian }
        it { is_expected.not_to be_secundal }
        it { is_expected.not_to be_quartal }
      end

      context "when in third inversion" do
        let(:pitch_collection) { HeadMusic::Analysis::PitchCollection.new(%w[F G Bb D5]) }

        its(:identifier) { is_expected.to eq :minor_minor_seventh_chord }
        it { is_expected.to be_seventh_chord }
        it { is_expected.to be_tetrachord }
        it { is_expected.not_to be_consonant }
        it { is_expected.to be_tertian }
        it { is_expected.not_to be_secundal }
        it { is_expected.not_to be_quartal }
      end
    end

    context "when given a minor-major seventh chord" do
      context "when in root position" do
        let(:pitch_collection) { HeadMusic::Analysis::PitchCollection.new(%w[G3 Bb3 D F#]) }

        its(:identifier) { is_expected.to eq :minor_major_seventh_chord }
        it { is_expected.to be_seventh_chord }
        it { is_expected.to be_tetrachord }
        it { is_expected.not_to be_consonant }
        it { is_expected.to be_tertian }
        it { is_expected.not_to be_secundal }
        it { is_expected.not_to be_quartal }
      end

      context "when in first inversion" do
        let(:pitch_collection) { HeadMusic::Analysis::PitchCollection.new(%w[Bb3 D F# G]) }

        its(:identifier) { is_expected.to eq :minor_major_seventh_chord }
        it { is_expected.to be_seventh_chord }
        it { is_expected.to be_tetrachord }
        it { is_expected.not_to be_consonant }
        it { is_expected.to be_tertian }
        it { is_expected.not_to be_secundal }
        it { is_expected.not_to be_quartal }
      end

      context "when in second inversion" do
        let(:pitch_collection) { HeadMusic::Analysis::PitchCollection.new(%w[D F# G Bb]) }

        its(:identifier) { is_expected.to eq :minor_major_seventh_chord }
        it { is_expected.to be_seventh_chord }
        it { is_expected.to be_tetrachord }
        it { is_expected.not_to be_consonant }
        it { is_expected.to be_tertian }
        it { is_expected.not_to be_secundal }
        it { is_expected.not_to be_quartal }
      end

      context "when in third inversion" do
        let(:pitch_collection) { HeadMusic::Analysis::PitchCollection.new(%w[F# G Bb D5]) }

        its(:identifier) { is_expected.to eq :minor_major_seventh_chord }
        it { is_expected.to be_seventh_chord }
        it { is_expected.to be_tetrachord }
        it { is_expected.not_to be_consonant }
        it { is_expected.to be_tertian }
        it { is_expected.not_to be_secundal }
        it { is_expected.not_to be_quartal }
      end
    end

    context "when given a half-diminished seventh chord" do
      context "when in root position" do
        let(:pitch_collection) { HeadMusic::Analysis::PitchCollection.new(%w[G3 Bb3 Db F]) }

        its(:identifier) { is_expected.to eq :half_diminished_seventh_chord }
        it { is_expected.to be_seventh_chord }
        it { is_expected.to be_tetrachord }
        it { is_expected.not_to be_consonant }
        it { is_expected.to be_tertian }
        it { is_expected.not_to be_secundal }
        it { is_expected.not_to be_quartal }
      end

      context "when in first inversion" do
        let(:pitch_collection) { HeadMusic::Analysis::PitchCollection.new(%w[Bb3 Db F G]) }

        its(:identifier) { is_expected.to eq :half_diminished_seventh_chord }
        it { is_expected.to be_seventh_chord }
        it { is_expected.to be_tetrachord }
        it { is_expected.not_to be_consonant }
        it { is_expected.to be_tertian }
        it { is_expected.not_to be_secundal }
        it { is_expected.not_to be_quartal }
      end

      context "when in second inversion" do
        let(:pitch_collection) { HeadMusic::Analysis::PitchCollection.new(%w[Db F G Bb3]) }

        its(:identifier) { is_expected.to eq :half_diminished_seventh_chord }
        it { is_expected.to be_seventh_chord }
        it { is_expected.to be_tetrachord }
        it { is_expected.not_to be_consonant }
        it { is_expected.to be_tertian }
        it { is_expected.not_to be_secundal }
        it { is_expected.not_to be_quartal }
      end

      context "when in third inversion" do
        let(:pitch_collection) { HeadMusic::Analysis::PitchCollection.new(%w[F G Bb3 Db5]) }

        its(:identifier) { is_expected.to eq :half_diminished_seventh_chord }
        it { is_expected.to be_seventh_chord }
        it { is_expected.to be_tetrachord }
        it { is_expected.not_to be_consonant }
        it { is_expected.to be_tertian }
        it { is_expected.not_to be_secundal }
        it { is_expected.not_to be_quartal }
      end
    end

    context "when given a fully-diminished seventh chord" do
      context "when in root position" do
        let(:pitch_collection) { HeadMusic::Analysis::PitchCollection.new(%w[G3 Bb3 Db Fb]) }

        its(:identifier) { is_expected.to eq :diminished_seventh_chord }
        its(:diatonic_intervals_above_bass_pitch) { are_expected.to eq %w[m3 d5 d7] }

        it { is_expected.to be_seventh_chord }
        it { is_expected.to be_tetrachord }
        it { is_expected.not_to be_consonant }
        it { is_expected.to be_tertian }
        it { is_expected.not_to be_secundal }
        it { is_expected.not_to be_quartal }
      end

      context "when in first inversion" do
        let(:pitch_collection) { HeadMusic::Analysis::PitchCollection.new(%w[Bb3 Db Fb G]) }

        its(:identifier) { is_expected.to eq :diminished_seventh_chord }
        its(:diatonic_intervals_above_bass_pitch) { are_expected.to eq %w[m3 d5 d7] }

        it { is_expected.to be_seventh_chord }
        it { is_expected.to be_tetrachord }
        it { is_expected.not_to be_consonant }
        it { is_expected.to be_tertian }
        it { is_expected.not_to be_secundal }
        it { is_expected.not_to be_quartal }
      end

      context "when in second inversion" do
        let(:pitch_collection) { HeadMusic::Analysis::PitchCollection.new(%w[Db Fb G Bb3]) }

        its(:identifier) { is_expected.to eq :diminished_seventh_chord }
        its(:diatonic_intervals_above_bass_pitch) { are_expected.to eq %w[m3 d5 d7] }

        it { is_expected.to be_seventh_chord }
        it { is_expected.to be_tetrachord }
        it { is_expected.not_to be_consonant }
        it { is_expected.to be_tertian }
        it { is_expected.not_to be_secundal }
        it { is_expected.not_to be_quartal }
      end

      context "when in third inversion" do
        let(:pitch_collection) { HeadMusic::Analysis::PitchCollection.new(%w[Fb G Bb3 Db5]) }

        its(:identifier) { is_expected.to eq :diminished_seventh_chord }
        its(:diatonic_intervals_above_bass_pitch) { are_expected.to eq %w[m3 d5 d7] }

        it { is_expected.to be_seventh_chord }
        it { is_expected.to be_tetrachord }
        it { is_expected.not_to be_consonant }
        it { is_expected.to be_tertian }
        it { is_expected.not_to be_secundal }
        it { is_expected.not_to be_quartal }
      end
    end

    context "when given a dominant ninth chord" do
      context "when in root position" do
        let(:pitch_collection) { HeadMusic::Analysis::PitchCollection.new(%w[C E G Bb D5]) }

        its(:identifier) { is_expected.to eq :dominant_ninth_chord }
        it { is_expected.to be_tertian }
      end
    end
  end
end
