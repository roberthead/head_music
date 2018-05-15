# frozen_string_literal: true

require 'spec_helper'

describe HeadMusic::Pitch::OctaveEquivalence do
  let(:pitch) { HeadMusic::Pitch.get('E♭4') }
  subject(:octave_equivalence) { described_class.get(pitch) }

  describe '#equivalent?' do
    it { is_expected.to be_octave_equivalent('E♭3') }

    it { is_expected.not_to be_octave_equivalent('E♭4') }
    it { is_expected.not_to be_octave_equivalent('E3') }
    it { is_expected.not_to be_octave_equivalent('E♯3') }
  end
end
