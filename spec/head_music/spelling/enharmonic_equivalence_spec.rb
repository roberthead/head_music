require "spec_helper"

describe HeadMusic::Rudiment::Spelling::EnharmonicEquivalence do
  subject(:enharmonic_equivalence) { described_class.get(identifier) }

  describe "#equivalent?" do
    let(:identifier) { HeadMusic::Rudiment::Spelling.get("D♯") }

    it { is_expected.to be_enharmonic_equivalent("E♭") }
    it { is_expected.to be_equivalent("E♭") }

    it { is_expected.not_to be_enharmonic_equivalent("D♯") }
    it { is_expected.not_to be_enharmonic_equivalent("D") }
    it { is_expected.not_to be_enharmonic_equivalent("E") }
  end
end
