require "spec_helper"

describe HeadMusic::KeySignature do
  describe ".new" do
    subject(:key_signature) { described_class.new(tonic, scale_type) }

    context "when given an instance" do
      let(:instance) { described_class.get("F♯ major") }

      it "returns that instance" do
        expect(described_class.get(instance)).to be instance
      end
    end

    context "when given only a tonic" do
      let(:scale_type) { nil }

      context "when Eb" do
        let(:tonic) { "E♭" }

        specify { expect(key_signature).to eq "E♭ major" }
        specify { expect(key_signature.num_flats).to eq 3 }
        specify { expect(key_signature.alterations).to eq ["B♭", "E♭", "A♭"] }
      end

      context "when Cb" do
        let(:tonic) { "C♭" }

        specify { expect(key_signature).to eq "C♭ major" }
        specify { expect(key_signature.num_flats).to eq 7 }
        specify { expect(key_signature.alterations).to eq ["B♭", "E♭", "A♭", "D♭", "G♭", "C♭", "F♭"] }
      end
    end

    context "when given the major scale_type" do
      let(:scale_type) { :major }

      context "when in the key of C major" do
        let(:tonic) { HeadMusic::Spelling.get("C") }

        specify { expect(key_signature.num_sharps).to eq 0 }
        specify { expect(key_signature.num_flats).to eq 0 }
        specify { expect(key_signature.alterations).to eq [] }
      end

      context "when in the key of E♭ major" do
        let(:tonic) { HeadMusic::Spelling.get("E♭") }

        specify { expect(key_signature.num_flats).to eq 3 }
        specify { expect(key_signature.alterations).to eq ["B♭", "E♭", "A♭"] }
      end

      context "when in the key of F♯ major" do
        let(:tonic) { HeadMusic::Spelling.get("F♯") }

        specify { expect(key_signature.num_sharps).to eq 6 }
        specify { expect(key_signature.alterations).to eq %w[F♯ C♯ G♯ D♯ A♯ E♯] }
      end

      context "when in the key of C♯ major" do
        let(:tonic) { HeadMusic::Spelling.get("C♯") }

        specify { expect(key_signature.num_sharps).to eq 7 }
        specify { expect(key_signature.alterations).to eq %w[F♯ C♯ G♯ D♯ A♯ E♯ B♯] }
      end

      context "when in the key of G♭ major" do
        let(:tonic) { HeadMusic::Spelling.get("G♭") }

        specify { expect(key_signature.alterations).to eq %w[B♭ E♭ A♭ D♭ G♭ C♭] }
        specify { expect(key_signature.num_alterations).to eq 6 }
      end

      context "when in the key of G♯ major" do
        let(:tonic) { HeadMusic::Spelling.get("G♯") }

        specify { expect(key_signature.num_sharps).to eq 8 }
        specify { expect(key_signature.num_alterations).to eq 8 }
        specify { expect(key_signature.alterations).to eq(%w[F𝄪 C♯ G♯ D♯ A♯ E♯ B♯]) }
      end

      context "when in the key of F♭ major" do
        let(:tonic) { HeadMusic::Spelling.get("F♭") }

        specify { expect(key_signature.num_flats).to eq 8 }
        specify { expect(key_signature.alterations).to eq(%w[B𝄫 E♭ A♭ D♭ G♭ C♭ F♭]) }

        its(:name) { is_expected.to eq "F♭ major" }
      end
    end

    context "when given the minor scale_type" do
      let(:scale_type) { :minor }

      context "when in the key of C minor" do
        let(:tonic) { HeadMusic::Spelling.get("C") }

        specify { expect(key_signature.num_flats).to eq 3 }
        specify { expect(key_signature.alterations).to eq ["B♭", "E♭", "A♭"] }

        its(:name) { is_expected.to eq "C minor" }
      end

      context "when in the key of B minor" do
        let(:tonic) { HeadMusic::Spelling.get("B") }

        specify { expect(key_signature.num_sharps).to eq 2 }

        specify { expect(key_signature.alterations).to eq ["F♯", "C♯"] }

        its(:name) { is_expected.to eq "B minor" }

        it { is_expected.not_to be_enharmonic_equivalent(described_class.get("D major")) }
        it { is_expected.to be_enharmonic_equivalent(described_class.get("Cb minor")) }
      end
    end

    context "when given the dorian scale_type" do
      let(:scale_type) { :dorian }
      let(:tonic) { "C" }

      specify { expect(key_signature.num_flats).to eq 2 }

      specify { expect(key_signature.flats).to eq ["B♭", "E♭"] }
      specify { expect(key_signature.alterations).to eq ["B♭", "E♭"] }
      specify { expect(key_signature.sharps_and_flats).to eq ["B♭", "E♭"] }
      specify { expect(key_signature.accidentals).to eq ["B♭", "E♭"] }
    end
  end

  describe "equality" do
    context "given a major key" do
      subject(:key_signature) { described_class.new(tonic, scale_type) }

      let(:tonic) { "E♭" }
      let(:scale_type) { :major }

      it "is equal to itself" do
        expect(key_signature).to eq described_class.get("E♭ major")
      end

      context "given other major keys" do
        specify { expect(key_signature).not_to eq described_class.get("E major") }
        specify { expect(key_signature).not_to eq described_class.get("B♭ major") }
      end

      it "is equal to the relative minor" do
        expect(key_signature).to eq described_class.get("C minor")
      end

      context "when a relative mode" do
        specify { expect(key_signature).to eq described_class.get("Eb ionian") }
        specify { expect(key_signature).to eq described_class.get("F dorian") }
        specify { expect(key_signature).to eq described_class.get("G phrygian") }
        specify { expect(key_signature).to eq described_class.get("Ab lydian") }
        specify { expect(key_signature).to eq described_class.get("Bb mixolydian") }
        specify { expect(key_signature).to eq described_class.get("C aeolian") }
        specify { expect(key_signature).to eq described_class.get("D locrian") }
      end

      context "with modes with the wrong final" do
        specify { expect(key_signature).not_to eq described_class.get("C ionian") }
        specify { expect(key_signature).not_to eq described_class.get("Eb dorian") }
        specify { expect(key_signature).not_to eq described_class.get("Eb phrygian") }
        specify { expect(key_signature).not_to eq described_class.get("Eb lydian") }
        specify { expect(key_signature).not_to eq described_class.get("Eb mixolydian") }
        specify { expect(key_signature).not_to eq described_class.get("Eb aeolian") }
        specify { expect(key_signature).not_to eq described_class.get("Eb locrian") }
      end
    end

    context "given a pentatonic scale type" do
      subject(:key_signature) { described_class.new(tonic, scale_type) }

      let(:tonic) { "D" }
      let(:scale_type) { :major_pentatonic }

      specify { expect(key_signature.num_sharps).to eq 2 }
      specify { expect(key_signature.alterations).to eq %w[F♯ C♯] }
    end
  end

  describe "#spellings" do
    specify { expect(described_class.get("D major").spellings).to eq %w[D E F♯ G A B C♯] }
  end

  describe "#to_s" do
    specify { expect(described_class.get("D major").to_s).to eq "2 sharps" }
    specify { expect(described_class.get("D minor").to_s).to eq "1 flat" }
    specify { expect(described_class.get("C major").to_s).to eq "no sharps or flats" }
  end
end
