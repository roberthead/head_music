require "spec_helper"

describe HeadMusic::Rudiment::Scale do
  describe "default scale" do
    specify { expect(described_class.get("G").spellings).to eq %w[G A B C D E F♯ G] }
  end

  describe "#pitch_names" do
    describe "default" do
      specify { expect(described_class.get("G").pitch_names).to eq %w[G4 A4 B4 C5 D5 E5 F♯5 G5] }
    end

    describe "accuracy" do
      specify { expect(described_class.get("C♯3", :major).pitch_names).to eq %w[C♯3 D♯3 E♯3 F♯3 G♯3 A♯3 B♯3 C♯4] }
      specify { expect(described_class.get("D4", :major).pitch_names).to eq %w[D4 E4 F♯4 G4 A4 B4 C♯5 D5] }
      specify { expect(described_class.get("F", :major).pitch_names).to eq %w[F4 G4 A4 B♭4 C5 D5 E5 F5] }

      specify { expect(described_class.get("F♯3", :natural_minor).pitch_names).to eq %w[F♯3 G♯3 A3 B3 C♯4 D4 E4 F♯4] }
      specify { expect(described_class.get("F♯3", :harmonic_minor).pitch_names).to eq %w[F♯3 G♯3 A3 B3 C♯4 D4 E♯4 F♯4] }
      specify { expect(described_class.get("F♯3", :melodic_minor).pitch_names).to eq %w[F♯3 G♯3 A3 B3 C♯4 D♯4 E♯4 F♯4] }

      specify { expect(described_class.get("D4", :harmonic_minor).pitch_names).to eq %w[D4 E4 F4 G4 A4 B♭4 C♯5 D5] }

      specify { expect(described_class.get("B♭4", :dorian).pitch_names).to eq %w[B♭4 C5 D♭5 E♭5 F5 G5 A♭5 B♭5] }
      specify { expect(described_class.get("B4", :locrian).pitch_names).to eq %w[B4 C5 D5 E5 F5 G5 A5 B5] }

      specify { expect(described_class.get("C4", :minor_pentatonic).pitch_names).to eq %w[C4 E♭4 F4 G4 B♭4 C5] }
      specify { expect(described_class.get("F♯", :major_pentatonic).pitch_names).to eq %w[F♯4 G♯4 A♯4 C♯5 D♯5 F♯5] }
      specify { expect(described_class.get("G♭", :major_pentatonic).pitch_names).to eq %w[G♭4 A♭4 B♭4 D♭5 E♭5 G♭5] }
      specify { expect(described_class.get("F", :minor_pentatonic).pitch_names).to eq %w[F4 A♭4 B♭4 C5 E♭5 F5] }

      specify { expect(described_class.get("C", :whole_tone).pitch_names).to eq %w[C4 D4 E4 F♯4 G♯4 A♯4 C5] }
      specify { expect(described_class.get("C♯", :whole_tone).pitch_names).to eq %w[C♯4 D♯4 F4 G4 A4 B4 C♯5] }
      specify { expect(described_class.get("D♭", :whole_tone).pitch_names).to eq %w[D♭4 E♭4 F4 G4 A4 B4 D♭5] }

      specify { expect(described_class.get("C", :chromatic).pitch_names).to eq %w[C4 C♯4 D4 D♯4 E4 F4 F♯4 G4 G♯4 A4 A♯4 B4 C5] }
      specify { expect(described_class.get("C♯", :chromatic).pitch_names).to eq %w[C♯4 D4 D♯4 E4 F4 F♯4 G4 G♯4 A4 A♯4 B4 C5 C♯5] }
    end

    describe "options" do
      subject(:scale) { described_class.get("C", :minor_pentatonic) }

      specify do
        expect(scale.pitch_names(direction: :both, octaves: 2))
          .to eq %w[C4 E♭4 F4 G4 B♭4 C5 E♭5 F5 G5 B♭5 C6 B♭5 G5 F5 E♭5 C5 B♭4 G4 F4 E♭4 C4]
      end

      specify do
        expect(scale.spellings(direction: :both, octaves: 2))
          .to eq %w[C E♭ F G B♭ C E♭ F G B♭ C6 B♭ G F E♭ C B♭ G F E♭ C]
      end
    end
  end

  describe "#degree" do
    let(:scale) { described_class.get("B♭", :major) }

    specify { expect(scale.degree(1)).to eq "B♭4" }
    specify { expect(scale.degree(2)).to eq "C5" }
  end

  describe "#pitches" do
    specify { expect(described_class.get("B♭", :dorian).pitch_names).to eq %w[B♭4 C5 D♭5 E♭5 F5 G5 A♭5 B♭5] }

    context "when descending" do
      specify do
        expect(described_class.get("C5", :melodic_minor).pitch_names(direction: :descending))
          .to eq %w[C5 B♭4 A♭4 G4 F4 E♭4 D4 C4]
      end
    end

    context "when ascending and descending" do
      specify do
        expect(described_class.get("C4", :melodic_minor).pitch_names(direction: :both))
          .to eq %w[C4 D4 E♭4 F4 G4 A4 B4 C5 B♭4 A♭4 G4 F4 E♭4 D4 C4]
      end
    end

    context "when two octaves up and down" do
      specify do
        expect(
          described_class.get("C4", :melodic_minor).pitch_names(direction: :both, octaves: 2)
        ).to eq %w[C4 D4 E♭4 F4 G4 A4 B4 C5 D5 E♭5 F5 G5 A5 B5 C6 B♭5 A♭5 G5 F5 E♭5 D5 C5 B♭4 A♭4 G4 F4 E♭4 D4 C4]
      end
    end
  end
end
