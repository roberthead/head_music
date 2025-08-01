require "spec_helper"

describe HeadMusic::Rudiment::Key do
  describe ".get" do
    subject { described_class.get(identifier) }

    context "when given 'C major'" do
      let(:identifier) { "C major" }

      it { is_expected.to be_a(described_class) }
      its(:tonic_spelling) { is_expected.to eq "C" }
      its(:quality) { is_expected.to eq :major }
      its(:name) { is_expected.to eq "C major" }
      its(:to_s) { is_expected.to eq "C major" }
      it { is_expected.to be_major }
      it { is_expected.not_to be_minor }
    end

    context "when given 'A minor'" do
      let(:identifier) { "A minor" }

      it { is_expected.to be_a(described_class) }
      its(:tonic_spelling) { is_expected.to eq "A" }
      its(:quality) { is_expected.to eq :minor }
      its(:name) { is_expected.to eq "A minor" }
      it { is_expected.not_to be_major }
      it { is_expected.to be_minor }
    end

    context "when given just a tonic" do
      let(:identifier) { "G" }

      its(:quality) { is_expected.to eq :major }
      its(:name) { is_expected.to eq "G major" }
    end

    context "when given an instance" do
      let(:instance) { described_class.get("D major") }
      let(:identifier) { instance }

      it "returns that instance" do
        expect(described_class.get(identifier)).to be instance
      end
    end
  end

  describe "#scale" do
    subject(:key) { described_class.get("C major") }

    it "returns the appropriate scale" do
      expect(key.scale).to be_a(HeadMusic::Rudiment::Scale)
      expect(key.scale.spellings.map(&:to_s)).to eq %w[C D E F G A B C]
    end
  end

  describe "#key_signature" do
    subject(:key) { described_class.get("D major") }

    it "returns the appropriate key signature" do
      expect(key.key_signature).to be_a(HeadMusic::Rudiment::KeySignature)
      expect(key.key_signature.sharps.map(&:to_s)).to eq %w[F♯ C♯]
    end
  end

  describe "#relative" do
    context "for a major key" do
      subject(:major_key) { described_class.get("C major") }

      it "returns the relative minor key" do
        expect(major_key.relative).to be_a(described_class)
        expect(major_key.relative.name).to eq "A minor"
      end
    end

    context "for a minor key" do
      subject(:minor_key) { described_class.get("A minor") }

      it "returns the relative major key" do
        expect(minor_key.relative).to be_a(described_class)
        expect(minor_key.relative.name).to eq "C major"
      end
    end
  end

  describe "#parallel" do
    context "for a major key" do
      subject(:major_key) { described_class.get("C major") }

      it "returns the parallel minor key" do
        expect(major_key.parallel).to be_a(described_class)
        expect(major_key.parallel.name).to eq "C minor"
      end
    end

    context "for a minor key" do
      subject(:minor_key) { described_class.get("C minor") }

      it "returns the parallel major key" do
        expect(minor_key.parallel).to be_a(described_class)
        expect(minor_key.parallel.name).to eq "C major"
      end
    end
  end

  describe "#==" do
    let(:first_c_major) { described_class.get("C major") }
    let(:second_c_major) { described_class.get("C major") }
    let(:c_minor) { described_class.get("C minor") }
    let(:d_major) { described_class.get("D major") }

    it "considers identical keys equal" do
      expect(first_c_major).to eq second_c_major
    end

    it "considers different keys unequal" do
      expect(first_c_major).not_to eq c_minor
      expect(first_c_major).not_to eq d_major
    end
  end
end
