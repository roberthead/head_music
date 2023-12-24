require "spec_helper"

describe HeadMusic::KeySignature::EnharmonicEquivalence do
  describe "#equivalent?" do
    context "when 5 sharps or 7 flats" do
      context "when B major" do
        subject(:key_signature) { described_class.get(HeadMusic::KeySignature.get("B major")) }

        it { is_expected.to be_enharmonic_equivalent(HeadMusic::KeySignature.get("C♭ major")) }
        it { is_expected.to be_enharmonic_equivalent(HeadMusic::KeySignature.get("A♭ minor")) }
        it { is_expected.not_to be_enharmonic_equivalent(HeadMusic::KeySignature.get("B major")) }
        it { is_expected.not_to be_enharmonic_equivalent(HeadMusic::KeySignature.get("G♯ minor")) }
        it { is_expected.not_to be_enharmonic_equivalent(HeadMusic::KeySignature.get("F♯ major")) }
        it { is_expected.not_to be_enharmonic_equivalent(HeadMusic::KeySignature.get("C♯ major")) }
      end

      context "when G♯ minor" do
        subject(:key_signature) { described_class.get(HeadMusic::KeySignature.get("G♯ minor")) }

        it { is_expected.to be_enharmonic_equivalent(HeadMusic::KeySignature.get("C♭ major")) }
        it { is_expected.to be_enharmonic_equivalent(HeadMusic::KeySignature.get("A♭ minor")) }
        it { is_expected.not_to be_enharmonic_equivalent(HeadMusic::KeySignature.get("B major")) }
        it { is_expected.not_to be_enharmonic_equivalent(HeadMusic::KeySignature.get("G♯ minor")) }
        it { is_expected.not_to be_enharmonic_equivalent(HeadMusic::KeySignature.get("F♯ major")) }
        it { is_expected.not_to be_enharmonic_equivalent(HeadMusic::KeySignature.get("C♯ major")) }
      end

      context "when C♭ major" do
        subject(:key_signature) { described_class.get(HeadMusic::KeySignature.get("C♭ major")) }

        it { is_expected.not_to be_enharmonic_equivalent(HeadMusic::KeySignature.get("C♭ major")) }
        it { is_expected.not_to be_enharmonic_equivalent(HeadMusic::KeySignature.get("A♭ minor")) }
        it { is_expected.to be_enharmonic_equivalent(HeadMusic::KeySignature.get("B major")) }
        it { is_expected.to be_enharmonic_equivalent(HeadMusic::KeySignature.get("G♯ minor")) }
        it { is_expected.not_to be_enharmonic_equivalent(HeadMusic::KeySignature.get("F♯ major")) }
        it { is_expected.not_to be_enharmonic_equivalent(HeadMusic::KeySignature.get("C♯ major")) }
      end

      context "when A♭ minor" do
        subject(:key_signature) { described_class.get(HeadMusic::KeySignature.get("A♭ minor")) }

        it { is_expected.not_to be_enharmonic_equivalent(HeadMusic::KeySignature.get("C♭ major")) }
        it { is_expected.not_to be_enharmonic_equivalent(HeadMusic::KeySignature.get("A♭ minor")) }
        it { is_expected.to be_enharmonic_equivalent(HeadMusic::KeySignature.get("B major")) }
        it { is_expected.to be_enharmonic_equivalent(HeadMusic::KeySignature.get("G♯ minor")) }
        it { is_expected.not_to be_enharmonic_equivalent(HeadMusic::KeySignature.get("F♯ major")) }
        it { is_expected.not_to be_enharmonic_equivalent(HeadMusic::KeySignature.get("C♯ major")) }
      end
    end

    context "when 6 sharps or 6 flats" do
      context "when F♯ major" do
        subject(:key_signature) { described_class.get(HeadMusic::KeySignature.get("F♯ major")) }

        it { is_expected.not_to be_enharmonic_equivalent(HeadMusic::KeySignature.get("F♯ major")) }
        it { is_expected.not_to be_enharmonic_equivalent(HeadMusic::KeySignature.get("D♯ minor")) }
        it { is_expected.to be_enharmonic_equivalent(HeadMusic::KeySignature.get("G♭ major")) }
        it { is_expected.to be_enharmonic_equivalent(HeadMusic::KeySignature.get("E♭ minor")) }

        it { is_expected.not_to be_enharmonic_equivalent(HeadMusic::KeySignature.get("C major")) }
      end

      context "when D♯ minor" do
        subject(:key_signature) { described_class.get(HeadMusic::KeySignature.get("D♯ minor")) }

        it { is_expected.not_to be_enharmonic_equivalent(HeadMusic::KeySignature.get("F♯ major")) }
        it { is_expected.not_to be_enharmonic_equivalent(HeadMusic::KeySignature.get("D♯ minor")) }
        it { is_expected.to be_enharmonic_equivalent(HeadMusic::KeySignature.get("G♭ major")) }
        it { is_expected.to be_enharmonic_equivalent(HeadMusic::KeySignature.get("E♭ minor")) }

        it { is_expected.not_to be_enharmonic_equivalent(HeadMusic::KeySignature.get("C major")) }
      end

      context "when G♭ major" do
        subject(:key_signature) { described_class.get(HeadMusic::KeySignature.get("G♭ major")) }

        it { is_expected.to be_enharmonic_equivalent(HeadMusic::KeySignature.get("F♯ major")) }
        it { is_expected.to be_enharmonic_equivalent(HeadMusic::KeySignature.get("D♯ minor")) }
        it { is_expected.not_to be_enharmonic_equivalent(HeadMusic::KeySignature.get("G♭ major")) }
        it { is_expected.not_to be_enharmonic_equivalent(HeadMusic::KeySignature.get("E♭ minor")) }

        it { is_expected.not_to be_enharmonic_equivalent(HeadMusic::KeySignature.get("C major")) }
      end

      context "when E♭ minor" do
        subject(:key_signature) { described_class.get(HeadMusic::KeySignature.get("E♭ minor")) }

        it { is_expected.to be_enharmonic_equivalent(HeadMusic::KeySignature.get("F♯ major")) }
        it { is_expected.to be_enharmonic_equivalent(HeadMusic::KeySignature.get("D♯ minor")) }
        it { is_expected.not_to be_enharmonic_equivalent(HeadMusic::KeySignature.get("G♭ major")) }
        it { is_expected.not_to be_enharmonic_equivalent(HeadMusic::KeySignature.get("E♭ minor")) }

        it { is_expected.not_to be_enharmonic_equivalent(HeadMusic::KeySignature.get("C major")) }
      end
    end

    context "when 7 sharps or 5 flats" do
      context "when C♯ major" do
        subject(:key_signature) { described_class.get(HeadMusic::KeySignature.get("C♯ major")) }

        it { is_expected.not_to be_enharmonic_equivalent(HeadMusic::KeySignature.get("C♯ major")) }
        it { is_expected.not_to be_enharmonic_equivalent(HeadMusic::KeySignature.get("A♯ minor")) }
        it { is_expected.to be_enharmonic_equivalent(HeadMusic::KeySignature.get("D♭ major")) }
        it { is_expected.to be_enharmonic_equivalent(HeadMusic::KeySignature.get("B♭ minor")) }

        it { is_expected.not_to be_enharmonic_equivalent(HeadMusic::KeySignature.get("C major")) }
      end

      context "when A♯ minor" do
        subject(:key_signature) { described_class.get(HeadMusic::KeySignature.get("A♯ minor")) }

        it { is_expected.not_to be_enharmonic_equivalent(HeadMusic::KeySignature.get("C♯ major")) }
        it { is_expected.not_to be_enharmonic_equivalent(HeadMusic::KeySignature.get("A♯ minor")) }
        it { is_expected.to be_enharmonic_equivalent(HeadMusic::KeySignature.get("D♭ major")) }
        it { is_expected.to be_enharmonic_equivalent(HeadMusic::KeySignature.get("B♭ minor")) }

        it { is_expected.not_to be_enharmonic_equivalent(HeadMusic::KeySignature.get("C major")) }
      end

      context "when D♭ major" do
        subject(:key_signature) { described_class.get(HeadMusic::KeySignature.get("D♭ major")) }

        it { is_expected.to be_enharmonic_equivalent(HeadMusic::KeySignature.get("C♯ major")) }
        it { is_expected.to be_enharmonic_equivalent(HeadMusic::KeySignature.get("A♯ minor")) }
        it { is_expected.not_to be_enharmonic_equivalent(HeadMusic::KeySignature.get("D♭ major")) }
        it { is_expected.not_to be_enharmonic_equivalent(HeadMusic::KeySignature.get("B♭ minor")) }

        it { is_expected.not_to be_enharmonic_equivalent(HeadMusic::KeySignature.get("C major")) }
      end

      context "when B♭ minor" do
        subject(:key_signature) { described_class.get(HeadMusic::KeySignature.get("B♭ minor")) }

        it { is_expected.to be_enharmonic_equivalent(HeadMusic::KeySignature.get("C♯ major")) }
        it { is_expected.to be_enharmonic_equivalent(HeadMusic::KeySignature.get("A♯ minor")) }
        it { is_expected.not_to be_enharmonic_equivalent(HeadMusic::KeySignature.get("D♭ major")) }
        it { is_expected.not_to be_enharmonic_equivalent(HeadMusic::KeySignature.get("B♭ minor")) }

        it { is_expected.not_to be_enharmonic_equivalent(HeadMusic::KeySignature.get("C major")) }
      end
    end
  end
end
