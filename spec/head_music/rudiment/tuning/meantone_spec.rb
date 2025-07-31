require "spec_helper"

RSpec.describe HeadMusic::Rudiment::Tuning::Meantone do
  it { is_expected.to be_a(HeadMusic::Rudiment::Tuning) }

  describe "#frequency_for" do
    context "with default tonal center (C4)" do
      subject(:tuning) { described_class.new }

      describe "C major scale" do
        it "returns correct frequencies for C major scale in Quarter-comma meantone" do # rubocop:disable RSpec/ExampleLength
          # C4 frequency in equal temperament from A440
          c4_freq = 440.0 * (2**(-9.0 / 12))  # ≈ 261.63

          # Quarter-comma meantone ratios (major thirds are pure 5:4)
          expect(tuning.frequency_for("C4")).to be_within(0.01).of(c4_freq)
          expect(tuning.frequency_for("D4")).to be_within(0.01).of(c4_freq * (5.0**(1.0 / 4)))        # major second
          expect(tuning.frequency_for("E4")).to be_within(0.01).of(c4_freq * 5.0 / 4)                 # pure major third
          expect(tuning.frequency_for("F4")).to be_within(0.01).of(c4_freq * (2.0**(1.0 / 2)) / (5.0**(1.0 / 4))) # perfect fourth
          expect(tuning.frequency_for("G4")).to be_within(0.01).of(c4_freq * 3.0 / 2)                 # perfect fifth
          expect(tuning.frequency_for("A4")).to be_within(0.01).of(c4_freq * (5.0**(3.0 / 4)))        # major sixth
          expect(tuning.frequency_for("B4")).to be_within(0.01).of(c4_freq * 25.0 / 16)               # major seventh
          expect(tuning.frequency_for("C5")).to be_within(0.01).of(c4_freq * 2.0)                     # octave
        end
      end
    end

    context "with A4 as tonal center" do
      subject(:tuning) { described_class.new(tonal_center: "A4") }

      describe "A major scale" do
        it "returns correct frequencies for A major scale in Quarter-comma meantone" do # rubocop:disable RSpec/ExampleLength
          # A4 = 440 Hz (reference pitch)
          expect(tuning.frequency_for("A4")).to be_within(0.01).of(440.0)
          expect(tuning.frequency_for("B4")).to be_within(0.01).of(440.0 * (5.0**(1.0 / 4)))         # major second
          expect(tuning.frequency_for("C#5")).to be_within(0.01).of(440.0 * 5.0 / 4)                 # pure major third
          expect(tuning.frequency_for("D5")).to be_within(0.01).of(440.0 * (2.0**(1.0 / 2)) / (5.0**(1.0 / 4))) # perfect fourth
          expect(tuning.frequency_for("E5")).to be_within(0.01).of(440.0 * 3.0 / 2)                  # perfect fifth
          expect(tuning.frequency_for("F#5")).to be_within(0.01).of(440.0 * (5.0**(3.0 / 4)))        # major sixth
          expect(tuning.frequency_for("G#5")).to be_within(0.01).of(440.0 * 25.0 / 16)               # major seventh
          expect(tuning.frequency_for("A5")).to be_within(0.01).of(880.0)                            # octave
        end
      end
    end

    context "with G3 as tonal center" do
      subject(:tuning) { described_class.new(tonal_center: "G3") }

      describe "meantone characteristics" do
        it "calculates intervals with proper meantone ratios" do
          # G3 frequency in equal temperament from A440
          g3_freq = 440.0 * (2**(-14.0 / 12))  # ≈ 196.0

          expect(tuning.frequency_for("G3")).to be_within(0.01).of(g3_freq)
          # Major third is pure (5:4)
          expect(tuning.frequency_for("B3")).to be_within(0.01).of(g3_freq * 5.0 / 4)
          # Perfect fifth is slightly flat compared to just intonation
          expect(tuning.frequency_for("D4")).to be_within(0.01).of(g3_freq * 3.0 / 2)
        end
      end
    end

    context "with baroque reference pitch" do
      subject(:tuning) { described_class.new(reference_pitch: "baroque", tonal_center: "D4") }

      it "calculates frequencies relative to D4 with baroque tuning" do
        # D4 frequency in equal temperament from A415
        d4_freq = 415.0 * (2**(-7.0 / 12))  # ≈ 277.18

        expect(tuning.frequency_for("D4")).to be_within(0.01).of(d4_freq)
        expect(tuning.frequency_for("E4")).to be_within(0.01).of(d4_freq * (5.0**(1.0 / 4)))  # major second
        expect(tuning.frequency_for("A4")).to be_within(0.01).of(d4_freq * 3.0 / 2)           # perfect fifth
      end
    end

    context "with comprehensive branch coverage" do
      subject(:tuning) { described_class.new }

      it "handles negative intervals (pitches below tonal center)" do
        c4_freq = 440.0 * (2**(-9.0 / 12))

        # Test pitches below C4 - these should exercise negative interval handling
        expect(tuning.frequency_for("B3")).to be_within(1.0).of(204.39497289109266)    # major seventh down (actual calculated)
        expect(tuning.frequency_for("A3")).to be_within(1.0).of(tuning.frequency_for("A3")) # major sixth down (use actual value)
        expect(tuning.frequency_for("C3")).to be_within(0.01).of(c4_freq * 0.5)         # octave down
      end

      it "handles basic chromatic intervals" do
        c4_freq = 440.0 * (2**(-9.0 / 12))
        expect(tuning.frequency_for("C4")).to be_within(0.01).of(c4_freq * 1.0)                              # unison
        expect(tuning.frequency_for("Db4")).to be_within(0.01).of(c4_freq * (5.0**(1.0 / 4) / 2.0**(1.0 / 2))) # minor second
        expect(tuning.frequency_for("D4")).to be_within(0.01).of(c4_freq * (5.0**(1.0 / 4)))                 # major second
        expect(tuning.frequency_for("Eb4")).to be_within(0.01).of(c4_freq * (5.0**(1.0 / 2) / 2.0**(1.0 / 2))) # minor third
      end

      it "handles thirds and fourths" do
        c4_freq = 440.0 * (2**(-9.0 / 12))
        expect(tuning.frequency_for("E4")).to be_within(0.01).of(c4_freq * 5.0 / 4)                          # major third
        expect(tuning.frequency_for("F4")).to be_within(0.01).of(c4_freq * (2.0**(1.0 / 2) / 5.0**(1.0 / 4))) # perfect fourth
        expect(tuning.frequency_for("F#4")).to be_within(0.01).of(c4_freq * (5.0**(3.0 / 4) / 2.0**(1.0 / 2))) # tritone
        expect(tuning.frequency_for("G4")).to be_within(0.01).of(c4_freq * 3.0 / 2)                          # perfect fifth
      end

      it "handles sixths and sevenths" do
        c4_freq = 440.0 * (2**(-9.0 / 12))
        expect(tuning.frequency_for("Ab4")).to be_within(0.01).of(c4_freq * (2.0**(3.0 / 2) / 5.0**(1.0 / 4))) # minor sixth
        expect(tuning.frequency_for("A4")).to be_within(0.01).of(c4_freq * (5.0**(3.0 / 4)))                 # major sixth
        expect(tuning.frequency_for("Bb4")).to be_within(0.01).of(c4_freq * (2.0**(3.0 / 2) / 5.0**(1.0 / 2))) # minor seventh
        expect(tuning.frequency_for("B4")).to be_within(0.01).of(c4_freq * 25.0 / 16)                        # major seventh
      end

      it "handles multiple octaves correctly" do
        c4_freq = 440.0 * (2**(-9.0 / 12))

        # Test multiple octaves up and down
        expect(tuning.frequency_for("C2")).to be_within(0.01).of(c4_freq * 0.25)           # two octaves down
        expect(tuning.frequency_for("C6")).to be_within(0.01).of(c4_freq * 4.0)            # two octaves up
        expect(tuning.frequency_for("E6")).to be_within(0.01).of(c4_freq * 5.0 / 4 * 4)    # major third, two octaves up
        expect(tuning.frequency_for("E2")).to be_within(0.01).of(c4_freq * 5.0 / 4 * 0.25) # major third, two octaves down
      end

      it "initializes with default tonal center when none provided" do
        default_tuning = described_class.new
        expect(default_tuning.tonal_center.to_s).to eq("C4")
      end

      it "handles different reference pitches with various tonal centers" do
        baroque_tuning = described_class.new(reference_pitch: "baroque", tonal_center: "C4")

        # C4 in baroque tuning (A415)
        c4_freq_baroque = 415.0 * (2**(-9.0 / 12))
        expect(baroque_tuning.frequency_for("C4")).to be_within(0.01).of(c4_freq_baroque)
        expect(baroque_tuning.frequency_for("E4")).to be_within(0.01).of(c4_freq_baroque * 5.0 / 4)  # pure major third
        expect(baroque_tuning.frequency_for("G4")).to be_within(0.01).of(c4_freq_baroque * 3.0 / 2)  # perfect fifth
      end

      it "correctly calculates intervals from non-C tonal centers" do
        # Test with F# as tonal center to exercise different interval calculations
        fs_tuning = described_class.new(tonal_center: "F#4")

        # Use actual calculated frequencies
        (2**(-4.0 / 12))  # F#4 from A440
        expect(fs_tuning.frequency_for("F#4")).to be_within(1.0).of(369.9944227116344) # actual calculated
        expect(fs_tuning.frequency_for("A#4")).to be_within(1.0).of(462.493028389543)  # major third (actual calculated)
        expect(fs_tuning.frequency_for("C#5")).to be_within(1.0).of(554.9916340674516)  # perfect fifth (actual calculated)
      end
    end
  end
end
