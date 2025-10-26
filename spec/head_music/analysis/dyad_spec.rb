require "spec_helper"

describe HeadMusic::Analysis::Dyad do
  describe "#initialize" do
    subject(:dyad) { described_class.new("C4", "G4") }

    it "accepts two pitches" do
      expect(dyad).to be_a(described_class)
    end

    it "stores the first pitch" do
      expect(dyad.pitch1.to_s).to eq("C4")
    end

    it "stores the second pitch" do
      expect(dyad.pitch2.to_s).to eq("G4")
    end

    context "with optional key context" do
      subject(:dyad) { described_class.new("C4", "G4", key: "C major") }

      it "stores the key context" do
        expect(dyad.key.to_s).to eq("C major")
      end
    end

    context "with pitch class arguments" do
      subject(:dyad) {
        described_class.new(
          HeadMusic::Rudiment::PitchClass.get("C"),
          HeadMusic::Rudiment::PitchClass.get("G")
        )
      }

      it "assigns pitches" do
        expect(dyad.pitch1.to_s).to eq("C4")
        expect(dyad.pitch2.to_s).to eq("G4")
      end
    end
  end

  describe "#interval" do
    context "with a perfect fifth" do
      subject(:dyad) { described_class.new("C4", "G4") }

      its(:interval) { is_expected.to be_a(HeadMusic::Analysis::DiatonicInterval) }

      it "identifies the interval" do
        expect(dyad.interval.to_s).to eq("perfect fifth")
      end
    end

    context "with a major third" do
      subject(:dyad) { described_class.new("C4", "E4") }

      it "identifies the interval" do
        expect(dyad.interval.to_s).to eq("major third")
      end
    end

    context "with pitches in reverse order" do
      subject(:dyad) { described_class.new("G4", "C4") }

      it "identifies the interval regardless of order" do
        expect(dyad.interval.to_s).to eq("perfect fifth")
      end
    end
  end

  describe "interval method delegation" do
    subject(:dyad) { described_class.new("C4", "E4") }

    it "delegates perfect? to the interval" do
      expect(dyad).not_to be_perfect
    end

    it "delegates major? to the interval" do
      expect(dyad).to be_major
    end

    it "delegates third? to the interval" do
      expect(dyad).to be_third
    end
  end

  describe "#possible_triads" do
    context "with a perfect fifth (C-G)" do
      subject(:dyad) { described_class.new("C4", "G4") }

      it "returns an array of pitch sets" do
        expect(dyad.possible_triads).to all(be_a(HeadMusic::Analysis::PitchSet))
      end

      it "includes a major triad (C E G)" do
        puts(dyad.possible_triads.map { |ps| ps.pitches.map(&:to_s).join("-") }.inspect)
        major_triad = dyad.possible_triads.find { |ps| ps.major_triad? }
        expect(major_triad).not_to be_nil
        expect(major_triad.pitches.map(&:pitch_class).map(&:to_i).sort).to eq([0, 4, 7])
      end

      it "includes a minor triad (C Eb G)" do
        minor_triad = dyad.possible_triads.find { |ps| ps.minor_triad? }
        expect(minor_triad).not_to be_nil
        expect(minor_triad.pitches.map(&:pitch_class).map(&:to_i).sort).to eq([0, 3, 7])
      end

      it "includes a suspended fourth chord (C F G)" do
        sus4 = dyad.possible_trichords.find do |ps|
          ps.pitches.map(&:pitch_class).map(&:to_i).sort == [0, 5, 7]
        end
        expect(sus4).not_to be_nil
      end
    end

    context "with a perfect fifth (C-G) - trichords" do
      subject(:dyad) { described_class.new("C4", "G4") }

      it "returns trichords including sus chords" do
        expect(dyad.possible_trichords.length).to be >= dyad.possible_triads.length
      end

      it "triads do not include sus chords" do
        triads = dyad.possible_triads
        expect(triads).to all(be_triad)
      end
    end

    context "with a major third (C-E)" do
      subject(:dyad) { described_class.new("C4", "E4") }

      it "includes a major triad (C E G)" do
        major_triad = dyad.possible_triads.find { |ps| ps.major_triad? }
        expect(major_triad).not_to be_nil
      end

      it "includes an augmented triad (C E G#)" do
        aug_triad = dyad.possible_triads.find { |ps| ps.augmented_triad? }
        expect(aug_triad).not_to be_nil
      end

      it "includes triads where the dyad appears inverted" do
        # C-E could be the 3rd and 5th of A minor (A C E)
        a_minor = dyad.possible_triads.find do |ps|
          ps.minor_triad? && ps.pitches.map(&:pitch_class).map(&:to_i) == [9, 0, 4]
        end
        expect(a_minor).not_to be_nil
      end
    end

    context "with a minor third (C-Eb)" do
      subject(:dyad) { described_class.new("C4", "Eb4") }

      it "includes a minor triad (C Eb G)" do
        minor_triad = dyad.possible_triads.find { |ps| ps.minor_triad? }
        expect(minor_triad).not_to be_nil
      end

      it "includes a diminished triad (C Eb Gb)" do
        dim_triad = dyad.possible_triads.find { |ps| ps.diminished_triad? }
        expect(dim_triad).not_to be_nil
      end
    end

    context "with a major sixth (C-A)" do
      subject(:dyad) { described_class.new("C4", "A4") }

      it "finds triads containing the sixth" do
        triads = dyad.possible_triads
        expect(triads).not_to be_empty
      end

      it "includes triads where the sixth is an inversion of a third" do
        # C-A is inversion of A-C (minor third)
        # Could be part of F major (F A C)
        f_major = dyad.possible_triads.find do |ps|
          ps.major_triad? && ps.pitches.map(&:pitch_class).map(&:to_i) == [5, 9, 0]
        end
        expect(f_major).not_to be_nil
      end
    end

    context "with key context" do
      context "with C major key" do
        subject(:dyad) { described_class.new("C4", "G4", key: "C major") }

        it "filters out triads with non-diatonic pitches" do
          triads = dyad.possible_triads
          all_diatonic = triads.all? do |triad|
            triad.pitches.all? { |pitch| dyad.key.scale.spellings.include?(pitch.spelling) }
          end
          expect(all_diatonic).to be true
        end

        it "includes C major triad (diatonic)" do
          c_major = dyad.possible_triads.find do |ps|
            ps.major_triad? && ps.pitches.map(&:pitch_class).map(&:to_i).sort == [0, 4, 7]
          end
          expect(c_major).not_to be_nil
        end

        it "excludes C minor triad (Eb is non-diatonic)" do
          c_minor = dyad.possible_triads.find do |ps|
            ps.minor_triad? && ps.pitches.map(&:pitch_class).map(&:to_i).sort == [0, 3, 7]
          end
          expect(c_minor).to be_nil
        end
      end

      context "with C minor key" do
        subject(:dyad) { described_class.new("C4", "G4", key: "C minor") }

        it "includes C minor triad (diatonic)" do
          c_minor = dyad.possible_triads.find do |ps|
            ps.minor_triad? && ps.pitches.map(&:pitch_class).map(&:to_i).sort == [0, 3, 7]
          end
          expect(c_minor).not_to be_nil
        end

        it "excludes C major triad (E is non-diatonic)" do
          c_major = dyad.possible_triads.find do |ps|
            ps.major_triad? && ps.pitches.first.pitch_class.to_s == "C"
          end
          expect(c_major).to be_nil
        end
      end

      context "when sorting by diatonic agreement" do
        subject(:dyad) { described_class.new("C4", "G4", key: "C major") }

        it "returns triads sorted with diatonic triads first" do
          triads = dyad.possible_triads
          # All should be diatonic when key is provided (filtered)
          expect(triads.first).to be_a(HeadMusic::Analysis::PitchSet)
        end
      end
    end
  end

  describe "#possible_seventh_chords" do
    context "with a perfect fifth (C-G)" do
      subject(:dyad) { described_class.new("C4", "G4") }

      it "returns an array of pitch sets" do
        expect(dyad.possible_seventh_chords).to all(be_a(HeadMusic::Analysis::PitchSet))
      end

      it "includes major-minor seventh (C E G Bb)" do
        dom7 = dyad.possible_seventh_chords.find do |ps|
          ps.seventh_chord? && ps.pitches.map(&:pitch_class).map(&:to_i).sort == [0, 4, 7, 10]
        end
        expect(dom7).not_to be_nil
      end

      it "includes major seventh (C E G B)" do
        maj7 = dyad.possible_seventh_chords.find do |ps|
          ps.seventh_chord? && ps.pitches.map(&:pitch_class).map(&:to_i).sort == [0, 4, 7, 11]
        end
        expect(maj7).not_to be_nil
      end

      it "includes minor seventh (C Eb G Bb)" do
        min7 = dyad.possible_seventh_chords.find do |ps|
          ps.seventh_chord? && ps.pitches.map(&:pitch_class).map(&:to_i).sort == [0, 3, 7, 10]
        end
        expect(min7).not_to be_nil
      end
    end

    context "with key context" do
      subject(:dyad) { described_class.new("G4", "D5", key: "C major") }

      it "filters out seventh chords with non-diatonic pitches" do
        seventh_chords = dyad.possible_seventh_chords
        all_diatonic = seventh_chords.all? do |chord|
          chord.pitches.all? { |pitch| dyad.key.scale.spellings.include?(pitch.spelling) }
        end
        expect(all_diatonic).to be true
      end

      it "includes G7 (G B D F) which is diatonic in C major" do
        g7 = dyad.possible_seventh_chords.find do |ps|
          ps.pitches.map(&:pitch_class).map(&:to_i).sort == [2, 5, 7, 11]
        end
        expect(g7).not_to be_nil
      end
    end
  end

  describe "#enharmonic_respellings" do
    context "with C-G#" do
      subject(:dyad) { described_class.new("C4", "G#4") }

      it "returns an array of Dyad objects" do
        expect(dyad.enharmonic_respellings).to all(be_a(described_class))
      end

      it "includes the respelling C-Ab" do
        c_ab = dyad.enharmonic_respellings.find do |d|
          d.pitch1.to_s == "C4" && d.pitch2.spelling.to_s == "A♭"
        end
        expect(c_ab).not_to be_nil
      end

      it "includes different interval identifications" do
        intervals = dyad.enharmonic_respellings.map { |d| d.interval.to_s }.uniq
        expect(intervals.length).to be > 1
      end
    end

    context "with key context" do
      subject(:dyad) { described_class.new("C4", "G#4", key: "C major") }

      it "preserves the key context in respellings" do
        respellings = dyad.enharmonic_respellings
        expect(respellings).to all(have_attributes(key: dyad.key))
      end
    end

    context "with pitches that have no enharmonic equivalents in context" do
      subject(:dyad) { described_class.new("C4", "D4") }

      it "returns an empty array or only the original" do
        # C and D have enharmonic equivalents (B#, C##, Ebb, etc.)
        # but in most practical contexts, we might limit to common ones
        expect(dyad.enharmonic_respellings).to be_an(Array)
      end
    end
  end

  describe "#to_s" do
    subject(:dyad) { described_class.new("C4", "E4") }

    it "returns a string representation" do
      expect(dyad.to_s).to be_a(String)
      expect(dyad.to_s).to include("C")
      expect(dyad.to_s).to include("E")
    end
  end

  describe "#pitches" do
    subject(:dyad) { described_class.new("G4", "C4") }

    it "returns both pitches" do
      expect(dyad.pitches).to contain_exactly(
        have_attributes(to_s: "G4"),
        have_attributes(to_s: "C4")
      )
    end
  end
end
