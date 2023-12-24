require "spec_helper"

describe HeadMusic::Pitch::OctaveEquivalence do
  subject(:octave_equivalence) { described_class.get(pitch) }

  let(:pitch) { HeadMusic::Pitch.get("E♭4") }

  describe "#equivalent?" do
    it { is_expected.to be_octave_equivalent("E♭3") }

    it { is_expected.not_to be_octave_equivalent("E♭4") }
    it { is_expected.not_to be_octave_equivalent("E3") }
    it { is_expected.not_to be_octave_equivalent("E♯3") }
  end
end
