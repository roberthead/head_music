require "spec_helper"

RSpec.describe HeadMusic::Rudiment::Tuning::Pythagorean do
  it { is_expected.to be_a(HeadMusic::Rudiment::Tuning) }

  describe "#frequency_for" do
    context "with default tonal center (C4)" do
      subject(:tuning) { described_class.new }

      describe "C major scale" do
        it "returns correct frequencies for C major scale in Pythagorean tuning" do # rubocop:disable RSpec/ExampleLength
          # C4 frequency in equal temperament from A440
          c4_freq = 440.0 * (2**(-9.0 / 12))  # ≈ 261.63

          # Pythagorean ratios are based on stacking perfect fifths (3:2)
          expect(tuning.frequency_for("C4")).to be_within(0.01).of(c4_freq)
          expect(tuning.frequency_for("D4")).to be_within(0.01).of(c4_freq * 9.0 / 8)     # major second
          expect(tuning.frequency_for("E4")).to be_within(0.01).of(c4_freq * 81.0 / 64)   # Pythagorean major third
          expect(tuning.frequency_for("F4")).to be_within(0.01).of(c4_freq * 4.0 / 3)     # perfect fourth
          expect(tuning.frequency_for("G4")).to be_within(0.01).of(c4_freq * 3.0 / 2)     # perfect fifth
          expect(tuning.frequency_for("A4")).to be_within(0.01).of(c4_freq * 27.0 / 16)   # Pythagorean major sixth
          expect(tuning.frequency_for("B4")).to be_within(0.01).of(c4_freq * 243.0 / 128) # Pythagorean major seventh
          expect(tuning.frequency_for("C5")).to be_within(0.01).of(c4_freq * 2.0)         # octave
        end
      end
    end

    context "with A4 as tonal center" do
      subject(:tuning) { described_class.new(tonal_center: "A4") }

      describe "A major scale" do
        it "returns correct frequencies for A major scale in Pythagorean tuning" do # rubocop:disable RSpec/ExampleLength
          # A4 = 440 Hz (reference pitch)
          expect(tuning.frequency_for("A4")).to be_within(0.01).of(440.0)
          expect(tuning.frequency_for("B4")).to be_within(0.01).of(440.0 * 9.0 / 8)      # major second
          expect(tuning.frequency_for("C#5")).to be_within(0.01).of(440.0 * 81.0 / 64)   # Pythagorean major third
          expect(tuning.frequency_for("D5")).to be_within(0.01).of(440.0 * 4.0 / 3)      # perfect fourth
          expect(tuning.frequency_for("E5")).to be_within(0.01).of(440.0 * 3.0 / 2)      # perfect fifth
          expect(tuning.frequency_for("F#5")).to be_within(0.01).of(440.0 * 27.0 / 16)   # Pythagorean major sixth
          expect(tuning.frequency_for("G#5")).to be_within(0.01).of(440.0 * 243.0 / 128) # Pythagorean major seventh
          expect(tuning.frequency_for("A5")).to be_within(0.01).of(880.0)                # octave
        end
      end
    end

    context "with G3 as tonal center" do
      subject(:tuning) { described_class.new(tonal_center: "G3") }

      describe "chromatic intervals" do
        it "calculates semitones using Pythagorean ratios" do
          # G3 frequency in equal temperament from A440
          g3_freq = 440.0 * (2**(-14.0 / 12))  # ≈ 196.0

          expect(tuning.frequency_for("G3")).to be_within(0.01).of(g3_freq)
          # Both G# and Ab are treated as minor seconds (1 semitone) in this implementation
          expect(tuning.frequency_for("G#3")).to be_within(0.01).of(g3_freq * 256.0 / 243)   # Pythagorean minor second
          expect(tuning.frequency_for("Ab3")).to be_within(0.01).of(g3_freq * 256.0 / 243)   # Pythagorean minor second
        end
      end
    end

    context "with baroque reference pitch" do
      subject(:tuning) { described_class.new(reference_pitch: "baroque", tonal_center: "D4") }

      it "calculates frequencies relative to D4 with baroque tuning" do
        # D4 frequency in equal temperament from A415
        d4_freq = 415.0 * (2**(-7.0 / 12))  # ≈ 277.18

        expect(tuning.frequency_for("D4")).to be_within(0.01).of(d4_freq)
        expect(tuning.frequency_for("E4")).to be_within(0.01).of(d4_freq * 9.0 / 8)     # major second
        expect(tuning.frequency_for("A4")).to be_within(0.01).of(d4_freq * 3.0 / 2)     # perfect fifth
      end
    end
  end
end
