require "spec_helper"

describe HeadMusic::Scale do
  describe "default scale" do
    specify { expect(described_class.get("G").spellings).to eq %w[G A B C D E F♯ G] }
  end

  describe "spelling" do
    describe "accuracy" do
      specify { expect(described_class.get("D4", :major).spellings).to eq %w[D E F♯ G A B C♯ D] }
      specify { expect(described_class.get("C♯3", :major).spellings).to eq %w[C♯ D♯ E♯ F♯ G♯ A♯ B♯ C♯] }
      specify { expect(described_class.get("F♯3", :natural_minor).spellings).to eq %w[F♯ G♯ A B C♯ D E F♯] }
      specify { expect(described_class.get("F♯3", :harmonic_minor).spellings).to eq %w[F♯ G♯ A B C♯ D E♯ F♯] }
      specify { expect(described_class.get("F♯3", :melodic_minor).spellings).to eq %w[F♯ G♯ A B C♯ D♯ E♯ F♯] }
      specify { expect(described_class.get("D", :harmonic_minor).spellings).to eq %w[D E F G A B♭ C♯ D] }
      specify { expect(described_class.get("B♭", :dorian).spellings).to eq %w[B♭ C D♭ E♭ F G A♭ B♭] }
      specify { expect(described_class.get("B", :locrian).spellings).to eq %w[B C D E F G A B] }
      specify { expect(described_class.get("C", :minor_pentatonic).spellings).to eq %w[C E♭ F G B♭ C] }
      specify { expect(described_class.get("F♯", :major_pentatonic).spellings).to eq %w[F♯ G♯ A♯ C♯ D♯ F♯] }
      specify { expect(described_class.get("G♭", :major_pentatonic).spellings).to eq %w[G♭ A♭ B♭ D♭ E♭ G♭] }
      specify { expect(described_class.get("F", :minor_pentatonic).spellings).to eq %w[F A♭ B♭ C E♭ F] }
      specify { expect(described_class.get("F", :major).spellings).to eq %w[F G A B♭ C D E F] }
      specify { expect(described_class.get("C", :whole_tone).spellings).to eq %w[C D E F♯ G♯ A♯ C] }
      specify { expect(described_class.get("C♯", :whole_tone).spellings).to eq %w[C♯ D♯ F G A B C♯] }
      specify { expect(described_class.get("D♭", :whole_tone).spellings).to eq %w[D♭ E♭ F G A B D♭] }
      specify { expect(described_class.get("C", :chromatic).spellings).to eq %w[C C♯ D D♯ E F F♯ G G♯ A A♯ B C] }
      specify { expect(described_class.get("C♯", :chromatic).spellings).to eq %w[C♯ D D♯ E F F♯ G G♯ A A♯ B C C♯] }
      specify { expect(described_class.get("C♯", :major).spellings).to eq %w[C♯ D♯ E♯ F♯ G♯ A♯ B♯ C♯] }
    end

    describe "options" do
      subject(:scale) { described_class.get("C", :minor_pentatonic) }

      specify do
        expect(scale.spellings(direction: :both, octaves: 2))
          .to eq %w[C E♭ F G B♭ C E♭ F G B♭ C B♭ G F E♭ C B♭ G F E♭ C]
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
