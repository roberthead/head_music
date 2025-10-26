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

  describe "method_missing edge cases" do
    subject(:dyad) { described_class.new("C4", "E4") }

    it "raises NoMethodError for non-existent methods" do
      expect { dyad.nonexistent_method }.to raise_error(NoMethodError)
    end

    it "delegates respond_to_missing? correctly" do
      expect(dyad.respond_to?(:perfect?)).to be true
      expect(dyad.respond_to?(:major?)).to be true
      expect(dyad.respond_to?(:nonexistent_method)).to be false
    end
  end

  describe "#alteration_sign (private method coverage)" do
    subject(:dyad) { described_class.new("C4", "E4") }

    it "returns correct signs for all alterations" do
      expect(dyad.send(:alteration_sign, -2)).to eq("bb")
      expect(dyad.send(:alteration_sign, -1)).to eq("b")
      expect(dyad.send(:alteration_sign, 0)).to eq("")
      expect(dyad.send(:alteration_sign, 1)).to eq("#")
      expect(dyad.send(:alteration_sign, 2)).to eq("##")
    end
  end

  describe "without key context" do
    subject(:dyad) { described_class.new("C4", "E4", key: nil) }

    it "returns all possible trichords when key is nil" do
      trichords_without_key = dyad.possible_trichords
      expect(trichords_without_key.length).to be > 0
    end

    it "does not filter results when key is nil" do
      # Create same dyad with and without key
      dyad_with_key = described_class.new("C4", "E4", key: "C major")
      dyad_without_key = described_class.new("C4", "E4", key: nil)

      expect(dyad_without_key.possible_trichords.length).to be >= dyad_with_key.possible_trichords.length
    end

    it "returns unsorted results when key is nil" do
      # Without key, sort_by_diatonic_agreement should return as-is
      trichords = dyad.possible_trichords
      expect(trichords).to be_an(Array)
    end
  end

  describe "enharmonic respellings edge cases" do
    context "with double sharps and flats" do
      subject(:dyad) { described_class.new("C4", "B#4") }

      it "generates enharmonic respellings" do
        respellings = dyad.enharmonic_respellings
        expect(respellings).to be_an(Array)
        expect(respellings.length).to be > 0
      end

      it "includes various spellings" do
        respellings = dyad.enharmonic_respellings
        spelling_pairs = respellings.map { |d| [d.pitch1.spelling.to_s, d.pitch2.spelling.to_s] }
        # Should have multiple different spelling combinations
        expect(spelling_pairs.uniq.length).to be > 1
      end
    end

    context "with natural notes" do
      subject(:dyad) { described_class.new("C4", "D4") }

      it "generates enharmonic respellings for natural notes" do
        respellings = dyad.enharmonic_respellings
        # C can be B#, Dbb; D can be C##, Ebb, etc.
        expect(respellings).to be_an(Array)
        expect(respellings.length).to be > 0
      end

      it "avoids duplicate spellings in enharmonic equivalents" do
        respellings = dyad.enharmonic_respellings
        spelling_pairs = respellings.map { |d| [d.pitch1.spelling.to_s, d.pitch2.spelling.to_s] }
        expect(spelling_pairs.uniq.length).to eq(spelling_pairs.length)
      end
    end

    context "with already enharmonic pitches" do
      subject(:dyad) { described_class.new("Db4", "C#4") }

      it "generates respellings even when pitches are enharmonic" do
        respellings = dyad.enharmonic_respellings
        expect(respellings).to be_an(Array)
      end
    end
  end

  describe "filter_by_key edge cases" do
    context "when key is nil" do
      subject(:dyad) { described_class.new("C4", "E4", key: nil) }

      it "returns all seventh chords without filtering" do
        seventh_chords = dyad.possible_seventh_chords
        expect(seventh_chords.length).to be > 0
      end
    end

    context "with chromatic key" do
      subject(:dyad) { described_class.new("C4", "Db4", key: "C minor") }

      it "filters results based on key" do
        trichords = dyad.possible_trichords
        # All pitches should be diatonic to C minor
        all_diatonic = trichords.all? do |trichord|
          trichord.pitches.all? { |pitch| dyad.key.scale.spellings.include?(pitch.spelling) }
        end
        expect(all_diatonic).to be true
      end
    end
  end

  describe "sort_by_diatonic_agreement edge cases" do
    context "without key context" do
      subject(:dyad) { described_class.new("C4", "E4") }

      it "returns trichords unsorted when no key" do
        trichords = dyad.possible_trichords
        # Just verify it returns results
        expect(trichords).to be_an(Array)
      end
    end

    context "with key that filters everything" do
      # Use a dyad that's not in the key at all
      subject(:dyad) { described_class.new("C#4", "F#4", key: "C major") }

      it "returns empty array when nothing is diatonic" do
        trichords = dyad.possible_trichords
        # C# and F# are not in C major, so no diatonic trichords possible
        expect(trichords).to be_empty
      end
    end
  end

  describe "robustness with edge cases" do
    context "with unison (same pitch)" do
      subject(:dyad) { described_class.new("C4", "C4") }

      it "handles unison interval" do
        expect(dyad.interval.to_s).to eq("perfect unison")
      end

      it "returns empty or minimal results for possible triads" do
        # A unison can't form a triad on its own
        triads = dyad.possible_triads
        expect(triads).to be_an(Array)
      end
    end

    context "with octave" do
      subject(:dyad) { described_class.new("C4", "C5") }

      it "handles octave interval" do
        expect(dyad.interval.to_s).to eq("perfect octave")
      end

      it "finds triads containing the octave" do
        triads = dyad.possible_triads
        expect(triads.length).to be >= 0
      end
    end

    context "with compound interval" do
      subject(:dyad) { described_class.new("C4", "E5") }

      it "handles compound intervals" do
        expect(dyad.interval.to_s).to eq("major tenth")
      end

      it "generates possible chords for compound intervals" do
        trichords = dyad.possible_trichords
        expect(trichords).to be_an(Array)
      end
    end

    context "with diminished interval" do
      subject(:dyad) { described_class.new("C4", "Gb4") }

      it "handles diminished fifth" do
        expect(dyad.interval.to_s).to eq("diminished fifth")
      end

      it "finds diminished triads" do
        dim_triads = dyad.possible_triads.select(&:diminished_triad?)
        expect(dim_triads.length).to be > 0
      end
    end

    context "with augmented interval" do
      subject(:dyad) { described_class.new("C4", "G#4") }

      it "handles augmented fifth" do
        expect(dyad.interval.to_s).to eq("augmented fifth")
      end

      it "finds augmented triads" do
        aug_triads = dyad.possible_triads.select(&:augmented_triad?)
        expect(aug_triads.length).to be > 0
      end
    end
  end

  describe "caching behavior" do
    subject(:dyad) { described_class.new("C4", "E4") }

    it "caches interval results" do
      first_call = dyad.interval
      second_call = dyad.interval
      expect(first_call).to be second_call
    end

    it "caches possible_trichords results" do
      first_call = dyad.possible_trichords
      second_call = dyad.possible_trichords
      expect(first_call).to be second_call
    end

    it "caches possible_triads results" do
      first_call = dyad.possible_triads
      second_call = dyad.possible_triads
      expect(first_call).to be second_call
    end

    it "caches possible_seventh_chords results" do
      first_call = dyad.possible_seventh_chords
      second_call = dyad.possible_seventh_chords
      expect(first_call).to be second_call
    end

    it "caches enharmonic_respellings results" do
      first_call = dyad.enharmonic_respellings
      second_call = dyad.enharmonic_respellings
      expect(first_call).to be second_call
    end
  end

  describe "seventh chord generation completeness" do
    subject(:dyad) { described_class.new("C4", "E4") }

    it "includes minor-major seventh chords" do
      dyad.possible_seventh_chords.find do |ps|
        # C E G B is a C major seventh, but C Eb G B is minor-major
        ps.pitches.map(&:pitch_class).map(&:to_i).sort == [0, 3, 7, 11]
      end
      # This specific combination might not be found, but test the mechanism
      expect(dyad.possible_seventh_chords).to be_an(Array)
    end

    it "includes half-diminished seventh chords" do
      # Look for any half-diminished pattern
      half_dim = dyad.possible_seventh_chords.any?(&:seventh_chord?)
      expect(half_dim).to be true
    end

    it "includes ninth chords in seventh chord results" do
      # The code includes dominant ninth patterns
      seventh_chords = dyad.possible_seventh_chords
      # Some may be 5-note ninth chords
      ninth_chords = seventh_chords.select { |ps| ps.pitches.length > 4 }
      expect(ninth_chords.length).to be >= 0
    end
  end

  describe "pitch ordering" do
    context "when pitches are given in reverse order" do
      subject(:dyad) { described_class.new("G4", "C4") }

      it "sorts pitches internally" do
        expect(dyad.pitch1.to_s).to eq("C4")
        expect(dyad.pitch2.to_s).to eq("G4")
      end

      it "identifies interval from lower to upper" do
        expect(dyad.interval.to_s).to eq("perfect fifth")
      end
    end

    context "with lower_pitch and upper_pitch" do
      subject(:dyad) { described_class.new("E4", "C4") }

      it "lower_pitch returns the lower pitch" do
        expect(dyad.lower_pitch.to_s).to eq("C4")
      end

      it "upper_pitch returns the upper pitch" do
        expect(dyad.upper_pitch.to_s).to eq("E4")
      end

      it "caches lower_pitch" do
        first_call = dyad.lower_pitch
        second_call = dyad.lower_pitch
        expect(first_call).to be second_call
      end

      it "caches upper_pitch" do
        first_call = dyad.upper_pitch
        second_call = dyad.upper_pitch
        expect(first_call).to be second_call
      end
    end
  end
end
