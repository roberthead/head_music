require "spec_helper"

RSpec.describe HeadMusic::Rudiment::Tuning::JustIntonation do
  it { is_expected.to be_a(HeadMusic::Rudiment::Tuning) }

  describe "#frequency_for" do
    context "with default tonal center (C4)" do
      subject(:tuning) { described_class.new }

      describe "C major scale" do
        it "returns correct frequencies for C major scale" do # rubocop:disable RSpec/ExampleLength
          # C4 frequency in equal temperament from A440
          c4_freq = 440.0 * (2**(-9.0 / 12))  # ≈ 261.63

          # All frequencies are relative to C4
          expect(tuning.frequency_for("C4")).to be_within(0.01).of(c4_freq)
          expect(tuning.frequency_for("D4")).to be_within(0.01).of(c4_freq * 9.0 / 8)   # major second
          expect(tuning.frequency_for("E4")).to be_within(0.01).of(c4_freq * 5.0 / 4)   # major third
          expect(tuning.frequency_for("F4")).to be_within(0.01).of(c4_freq * 4.0 / 3)   # perfect fourth
          expect(tuning.frequency_for("G4")).to be_within(0.01).of(c4_freq * 3.0 / 2)   # perfect fifth
          expect(tuning.frequency_for("A4")).to be_within(0.01).of(c4_freq * 5.0 / 3)   # major sixth
          expect(tuning.frequency_for("B4")).to be_within(0.01).of(c4_freq * 15.0 / 8)  # major seventh
          expect(tuning.frequency_for("C5")).to be_within(0.01).of(c4_freq * 2.0)     # octave
        end
      end
    end

    context "with A4 as tonal center" do
      subject(:tuning) { described_class.new(tonal_center: "A4") }

      describe "A major scale" do
        it "returns correct frequencies for A major scale" do # rubocop:disable RSpec/ExampleLength
          # A4 = 440 Hz (reference pitch)
          expect(tuning.frequency_for("A4")).to be_within(0.01).of(440.0)
          expect(tuning.frequency_for("B4")).to be_within(0.01).of(440.0 * 9.0 / 8)   # major second
          expect(tuning.frequency_for("C#5")).to be_within(0.01).of(440.0 * 5.0 / 4)  # major third
          expect(tuning.frequency_for("D5")).to be_within(0.01).of(440.0 * 4.0 / 3)   # perfect fourth
          expect(tuning.frequency_for("E5")).to be_within(0.01).of(440.0 * 3.0 / 2)   # perfect fifth
          expect(tuning.frequency_for("F#5")).to be_within(0.01).of(440.0 * 5.0 / 3)  # major sixth
          expect(tuning.frequency_for("G#5")).to be_within(0.01).of(440.0 * 15.0 / 8) # major seventh
          expect(tuning.frequency_for("A5")).to be_within(0.01).of(880.0)          # octave
        end
      end
    end

    context "with G3 as tonal center" do
      subject(:tuning) { described_class.new(tonal_center: "G3") }

      describe "G major scale" do
        it "returns correct frequencies for G major scale" do # rubocop:disable RSpec/ExampleLength
          # G3 frequency in equal temperament from A440
          g3_freq = 440.0 * (2**(-14.0 / 12))  # ≈ 196.0

          expect(tuning.frequency_for("G3")).to be_within(0.01).of(g3_freq)
          expect(tuning.frequency_for("A3")).to be_within(0.01).of(g3_freq * 9.0 / 8)   # major second
          expect(tuning.frequency_for("B3")).to be_within(0.01).of(g3_freq * 5.0 / 4)   # major third
          expect(tuning.frequency_for("C4")).to be_within(0.01).of(g3_freq * 4.0 / 3)   # perfect fourth
          expect(tuning.frequency_for("D4")).to be_within(0.01).of(g3_freq * 3.0 / 2)   # perfect fifth
          expect(tuning.frequency_for("E4")).to be_within(0.01).of(g3_freq * 5.0 / 3)   # major sixth
          expect(tuning.frequency_for("F#4")).to be_within(0.01).of(g3_freq * 15.0 / 8) # major seventh
          expect(tuning.frequency_for("G4")).to be_within(0.01).of(g3_freq * 2.0)     # octave
        end
      end
    end

    context "with baroque reference pitch and D4 tonal center" do
      subject(:tuning) { described_class.new(reference_pitch: "baroque", tonal_center: "D4") }

      it "calculates frequencies relative to D4 with baroque tuning" do
        # D4 frequency in equal temperament from A415
        d4_freq = 415.0 * (2**(-7.0 / 12))  # ≈ 277.18

        expect(tuning.frequency_for("D4")).to be_within(0.01).of(d4_freq)
        expect(tuning.frequency_for("E4")).to be_within(0.01).of(d4_freq * 9.0 / 8)   # major second
        expect(tuning.frequency_for("A4")).to be_within(0.01).of(d4_freq * 3.0 / 2)   # perfect fifth
      end
    end

    context "with edge cases and error conditions" do
      subject(:tuning) { described_class.new }

      it "handles negative intervals (pitches below tonal center)" do
        # Test pitches below C4
        c4_freq = 440.0 * (2**(-9.0 / 12))

        expect(tuning.frequency_for("B3")).to be_within(0.01).of(c4_freq * 15.0 / 16)  # minor seventh down = minor second up inverted
        expect(tuning.frequency_for("Bb3")).to be_within(0.01).of(c4_freq * 16.0 / 18) # minor seventh down
        expect(tuning.frequency_for("A3")).to be_within(0.01).of(c4_freq * 5.0 / 6)   # major sixth down = minor third up inverted
        expect(tuning.frequency_for("C3")).to be_within(0.01).of(c4_freq * 0.5)       # octave down
      end

      it "handles minor chromatic intervals" do
        c4_freq = 440.0 * (2**(-9.0 / 12))
        expect(tuning.frequency_for("Db4")).to be_within(0.01).of(c4_freq * 16.0 / 15) # minor second
        expect(tuning.frequency_for("Eb4")).to be_within(0.01).of(c4_freq * 6.0 / 5)   # minor third
      end

      it "handles augmented and diminished intervals" do
        c4_freq = 440.0 * (2**(-9.0 / 12))
        expect(tuning.frequency_for("F#4")).to be_within(0.01).of(c4_freq * 45.0 / 32) # tritone
        expect(tuning.frequency_for("Ab4")).to be_within(0.01).of(c4_freq * 8.0 / 5)   # minor sixth
        expect(tuning.frequency_for("Bb4")).to be_within(0.01).of(c4_freq * 16.0 / 9)  # minor seventh
      end

      it "handles multiple octaves" do
        c4_freq = 440.0 * (2**(-9.0 / 12))

        # Test pitches in different octaves
        expect(tuning.frequency_for("C2")).to be_within(0.01).of(c4_freq * 0.25)       # two octaves down
        expect(tuning.frequency_for("C6")).to be_within(0.01).of(c4_freq * 4.0)        # two octaves up
        expect(tuning.frequency_for("G6")).to be_within(0.01).of(c4_freq * 3.0 / 2 * 4) # perfect fifth, two octaves up
      end

      it "initializes with default tonal center when none provided" do
        tuning_no_center = described_class.new
        expect(tuning_no_center.tonal_center.to_s).to eq("C4")
      end

      it "handles different reference pitches with tonal centers" do
        tuning_baroque = described_class.new(reference_pitch: "baroque", tonal_center: "C4")

        # C4 in baroque tuning (A415)
        c4_freq_baroque = 415.0 * (2**(-9.0 / 12))
        expect(tuning_baroque.frequency_for("C4")).to be_within(0.01).of(c4_freq_baroque)
        expect(tuning_baroque.frequency_for("G4")).to be_within(0.01).of(c4_freq_baroque * 3.0 / 2)
      end
    end
  end
end
