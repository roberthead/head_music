require "spec_helper"

describe HeadMusic::Rudiment::Mode do
  describe ".get" do
    subject { described_class.get(identifier) }

    context "when given 'C ionian'" do
      let(:identifier) { "C ionian" }

      it { is_expected.to be_a(described_class) }
      its(:tonic_spelling) { is_expected.to eq "C" }
      its(:mode_name) { is_expected.to eq :ionian }
      its(:name) { is_expected.to eq "C ionian" }
      its(:to_s) { is_expected.to eq "C ionian" }
    end

    context "when given 'D dorian'" do
      let(:identifier) { "D dorian" }

      it { is_expected.to be_a(described_class) }
      its(:tonic_spelling) { is_expected.to eq "D" }
      its(:mode_name) { is_expected.to eq :dorian }
      its(:name) { is_expected.to eq "D dorian" }
    end

    context "when given just a tonic" do
      let(:identifier) { "G" }

      its(:mode_name) { is_expected.to eq :ionian }
      its(:name) { is_expected.to eq "G ionian" }
    end

    context "when given an instance" do
      let(:instance) { described_class.get("F lydian") }
      let(:identifier) { instance }

      it "returns that instance" do
        expect(described_class.get(identifier)).to be instance
      end
    end
  end

  describe "#scale" do
    subject(:mode) { described_class.get("D dorian") }

    it "returns the appropriate scale" do
      expect(mode.scale).to be_a(HeadMusic::Rudiment::Scale)
      expect(mode.scale.spellings.map(&:to_s)).to eq %w[D E F G A B C D]
    end
  end

  describe "#key_signature" do
    subject(:mode) { described_class.get("D dorian") }

    it "returns the appropriate key signature" do
      expect(mode.key_signature).to be_a(HeadMusic::Rudiment::KeySignature)
      # D dorian has the same key signature as C major (no sharps or flats)
      expect(mode.key_signature.sharps).to be_empty
      expect(mode.key_signature.flats).to be_empty
    end
  end

  describe "#relative_major" do
    context "for ionian mode" do
      subject(:ionian_mode) { described_class.get("C ionian") }

      it "returns the equivalent major key" do
        expect(ionian_mode.relative_major).to be_a(HeadMusic::Rudiment::Key)
        expect(ionian_mode.relative_major.name).to eq "C major"
      end
    end

    context "for dorian mode" do
      subject(:dorian_mode) { described_class.get("D dorian") }

      it "returns the relative major key" do
        expect(dorian_mode.relative_major).to be_a(HeadMusic::Rudiment::Key)
        expect(dorian_mode.relative_major.name).to eq "C major"
      end
    end

    context "for phrygian mode" do
      subject(:phrygian_mode) { described_class.get("E phrygian") }

      it "returns the relative major key" do
        expect(phrygian_mode.relative_major).to be_a(HeadMusic::Rudiment::Key)
        expect(phrygian_mode.relative_major.name).to eq "C major"
      end
    end

    context "for lydian mode" do
      subject(:lydian_mode) { described_class.get("F lydian") }

      it "returns the relative major key" do
        expect(lydian_mode.relative_major).to be_a(HeadMusic::Rudiment::Key)
        expect(lydian_mode.relative_major.name).to eq "C major"
      end
    end

    context "for mixolydian mode" do
      subject(:mixolydian_mode) { described_class.get("G mixolydian") }

      it "returns the relative major key" do
        expect(mixolydian_mode.relative_major).to be_a(HeadMusic::Rudiment::Key)
        expect(mixolydian_mode.relative_major.name).to eq "C major"
      end
    end

    context "for aeolian mode" do
      subject(:aeolian_mode) { described_class.get("A aeolian") }

      it "returns the relative major key" do
        expect(aeolian_mode.relative_major).to be_a(HeadMusic::Rudiment::Key)
        expect(aeolian_mode.relative_major.name).to eq "C major"
      end
    end

    context "for locrian mode" do
      subject(:locrian_mode) { described_class.get("B locrian") }

      it "returns the relative major key" do
        expect(locrian_mode.relative_major).to be_a(HeadMusic::Rudiment::Key)
        expect(locrian_mode.relative_major.name).to eq "C major"
      end
    end
  end

  describe "#parallel" do
    context "for ionian mode" do
      subject(:ionian_mode) { described_class.get("C ionian") }

      it "returns the parallel major key" do
        expect(ionian_mode.parallel).to be_a(HeadMusic::Rudiment::Key)
        expect(ionian_mode.parallel.name).to eq "C major"
      end
    end

    context "for dorian mode" do
      subject(:dorian_mode) { described_class.get("D dorian") }

      it "returns the parallel minor key" do
        expect(dorian_mode.parallel).to be_a(HeadMusic::Rudiment::Key)
        expect(dorian_mode.parallel.name).to eq "D minor"
      end
    end

    context "for phrygian mode" do
      subject(:phrygian_mode) { described_class.get("E phrygian") }

      it "returns the parallel minor key" do
        expect(phrygian_mode.parallel).to be_a(HeadMusic::Rudiment::Key)
        expect(phrygian_mode.parallel.name).to eq "E minor"
      end
    end

    context "for lydian mode" do
      subject(:lydian_mode) { described_class.get("F lydian") }

      it "returns the parallel major key" do
        expect(lydian_mode.parallel).to be_a(HeadMusic::Rudiment::Key)
        expect(lydian_mode.parallel.name).to eq "F major"
      end
    end

    context "for mixolydian mode" do
      subject(:mixolydian_mode) { described_class.get("G mixolydian") }

      it "returns the parallel major key" do
        expect(mixolydian_mode.parallel).to be_a(HeadMusic::Rudiment::Key)
        expect(mixolydian_mode.parallel.name).to eq "G major"
      end
    end

    context "for aeolian mode" do
      subject(:aeolian_mode) { described_class.get("A aeolian") }

      it "returns the parallel minor key" do
        expect(aeolian_mode.parallel).to be_a(HeadMusic::Rudiment::Key)
        expect(aeolian_mode.parallel.name).to eq "A minor"
      end
    end

    context "for locrian mode" do
      subject(:locrian_mode) { described_class.get("B locrian") }

      it "returns the parallel minor key" do
        expect(locrian_mode.parallel).to be_a(HeadMusic::Rudiment::Key)
        expect(locrian_mode.parallel.name).to eq "B minor"
      end
    end
  end

  describe "#==" do
    let(:first_d_dorian) { described_class.get("D dorian") }
    let(:second_d_dorian) { described_class.get("D dorian") }
    let(:d_phrygian) { described_class.get("D phrygian") }
    let(:e_dorian) { described_class.get("E dorian") }

    it "considers identical modes equal" do
      expect(first_d_dorian).to eq second_d_dorian
    end

    it "considers different modes unequal" do
      expect(first_d_dorian).not_to eq d_phrygian
      expect(first_d_dorian).not_to eq e_dorian
    end
  end
end
