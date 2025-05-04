require "spec_helper"

describe HeadMusic::Rudiment::IntervalCycle do
  describe "construction" do
    context "when given a diatonic interval" do
      subject(:diminished_seventh_sonority) { described_class.new(interval: :minor_third) }

      let(:minor_third) { HeadMusic::Analysis::DiatonicInterval.get(:minor_third) }

      its(:interval) { is_expected.to eq minor_third }

      describe "#pitches" do
        it "returns a list of pitches until the first repeated pitch class" do
          expect(diminished_seventh_sonority.pitches.map(&:to_s)).to eq(%w[C4 E♭4 G♭4 B𝄫4])
        end
      end

      describe "#spellings" do
        it "returns a list of spellings until the first repeated pitch class" do
          expect(diminished_seventh_sonority.spellings.map(&:to_s)).to eq(%w[C E♭ G♭ B𝄫])
        end
      end

      describe "#pitch_class_set" do
        it "returns a list of pitches until the first repeated pitch class" do
          expect(diminished_seventh_sonority.pitch_class_set).to eq HeadMusic::Rudiment::PitchClassSet.new(%w[C Eb Gb Bbb])
        end
      end
    end

    context "when given a number of steps as the interval" do
      subject(:diminished_seventh_sonority) { described_class.new(interval: 3) }

      its(:interval) { is_expected.to eq HeadMusic::Rudiment::ChromaticInterval.get(3) }

      describe "#pitches" do
        it "returns a list of pitches before the first repeated pitch class" do
          expect(diminished_seventh_sonority.pitches.map(&:to_s)).to eq(%w[C4 D♯4 F♯4 A4])
        end
      end

      describe "#pitch_class_set" do
        it "returns a list of pitches until the first repeated pitch class" do
          expect(diminished_seventh_sonority.pitch_class_set).to eq HeadMusic::Rudiment::PitchClassSet.new(%w[C Eb Gb Bbb])
        end
      end
    end

    context "when specifying a starting pitch" do
      subject(:augmented_triad_sonority) do
        described_class.new(interval: :major_third, starting_pitch: "Ab3")
      end

      let(:major_third) { HeadMusic::Analysis::DiatonicInterval.get(:major_third) }

      describe "#pitches" do
        it "returns a list of pitches until the first repeated pitch class" do
          expect(augmented_triad_sonority.pitches.map(&:to_s)).to eq(%w[A♭3 C4 E4])
        end
      end
    end
  end

  describe ".get" do
    context "when the identifier is a named cycle" do
      specify { expect(described_class.get("C0").pitches.length).to eq 1 }
      specify { expect(described_class.get("C1").pitches.length).to eq 12 }
      specify { expect(described_class.get("C2").pitches.length).to eq 6 }
      specify { expect(described_class.get("C3").pitches.length).to eq 4 }
      specify { expect(described_class.get("C4").pitches.length).to eq 3 }
      specify { expect(described_class.get("C5").pitches.length).to eq 12 }
      specify { expect(described_class.get("C6").pitches.length).to eq 2 }
      specify { expect(described_class.get("C7").pitches.length).to eq 12 }
      specify { expect(described_class.get("C8").pitches.length).to eq 3 }
      specify { expect(described_class.get("C9").pitches.length).to eq 4 }
      specify { expect(described_class.get("C10").pitches.length).to eq 6 }
      specify { expect(described_class.get("C11").pitches.length).to eq 12 }
    end

    context "when the identifier is an integer" do
      specify { expect(described_class.get(6).pitches.length).to eq 2 }
    end
  end
end
