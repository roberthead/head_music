require "spec_helper"

describe HeadMusic::Rudiment::Pitch::EnharmonicEquivalence do
  subject(:enharmonic_equivalence) { described_class.get(pitch) }

  describe "#equivalent?" do
    let(:pitch) { HeadMusic::Rudiment::Pitch.get("D#3") }

    it { is_expected.to be_enharmonic_equivalent("E♭3") }
    it { is_expected.to be_equivalent("E♭3") }

    it { is_expected.not_to be_enharmonic_equivalent("E♭4") }
    it { is_expected.not_to be_enharmonic_equivalent("E3") }
    it { is_expected.not_to be_enharmonic_equivalent("E♯3") }
  end
end
