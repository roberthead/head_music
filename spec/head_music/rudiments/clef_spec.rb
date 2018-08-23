# frozen_string_literal: true

require 'spec_helper'

describe HeadMusic::Clef do
  subject(:clef) { described_class.get(name) }

  context 'treble clef' do
    let(:name) { :treble }

    it { is_expected.to be_modern }
    its(:clef_type) { is_expected.to eq 'G-clef' }

    specify { expect(clef.pitch_for_space(-1)).to eq 'B3' }
    specify { expect(clef.pitch_for_line(0)).to eq 'C4' }
    specify { expect(clef.pitch_for_space(0)).to eq 'D4' }

    specify { expect(clef.pitch_for_line(1)).to eq 'E4' }
    specify { expect(clef.pitch_for_space(1)).to eq 'F4' }
    specify { expect(clef.pitch_for_line(2)).to eq 'G4' }
    specify { expect(clef.pitch_for_space(2)).to eq 'A4' }
    specify { expect(clef.pitch_for_line(3)).to eq 'B4' }
    specify { expect(clef.pitch_for_space(3)).to eq 'C5' }
    specify { expect(clef.pitch_for_line(4)).to eq 'D5' }
    specify { expect(clef.pitch_for_space(4)).to eq 'E5' }
    specify { expect(clef.pitch_for_line(5)).to eq 'F5' }

    specify { expect(clef.pitch_for_space(5)).to eq 'G5' }
    specify { expect(clef.pitch_for_line(7)).to eq 'C6' }
  end

  context 'alto clef' do
    let(:name) { :alto }

    it { is_expected.to be_modern }
    its(:clef_type) { is_expected.to eq 'C-clef' }

    specify { expect(clef.pitch_for_space(-1)).to eq 'C3' }
    specify { expect(clef.pitch_for_line(0)).to eq 'D3' }
    specify { expect(clef.pitch_for_space(0)).to eq 'E3' }

    specify { expect(clef.pitch_for_line(1)).to eq 'F3' }
    specify { expect(clef.pitch_for_space(1)).to eq 'G3' }
    specify { expect(clef.pitch_for_line(2)).to eq 'A3' }
    specify { expect(clef.pitch_for_space(2)).to eq 'B3' }
    specify { expect(clef.pitch_for_line(3)).to eq 'C4' }
    specify { expect(clef.pitch_for_space(3)).to eq 'D4' }
    specify { expect(clef.pitch_for_line(4)).to eq 'E4' }
    specify { expect(clef.pitch_for_space(4)).to eq 'F4' }
    specify { expect(clef.pitch_for_line(5)).to eq 'G4' }

    specify { expect(clef.pitch_for_space(5)).to eq 'A4' }
    specify { expect(clef.pitch_for_line(7)).to eq 'D5' }
  end

  context 'bass clef' do
    let(:name) { :bass }

    it { is_expected.to be_modern }
    its(:clef_type) { is_expected.to eq 'F-clef' }

    specify { expect(clef.pitch_for_space(-1)).to eq 'D2' }
    specify { expect(clef.pitch_for_line(0)).to eq 'E2' }
    specify { expect(clef.pitch_for_space(0)).to eq 'F2' }

    specify { expect(clef.pitch_for_line(1)).to eq 'G2' }
    specify { expect(clef.pitch_for_space(1)).to eq 'A2' }
    specify { expect(clef.pitch_for_line(2)).to eq 'B2' }
    specify { expect(clef.pitch_for_space(2)).to eq 'C3' }
    specify { expect(clef.pitch_for_line(3)).to eq 'D3' }
    specify { expect(clef.pitch_for_space(3)).to eq 'E3' }
    specify { expect(clef.pitch_for_line(4)).to eq 'F3' }
    specify { expect(clef.pitch_for_space(4)).to eq 'G3' }
    specify { expect(clef.pitch_for_line(5)).to eq 'A3' }

    specify { expect(clef.pitch_for_space(5)).to eq 'B3' }
    specify { expect(clef.pitch_for_line(6)).to eq 'C4' }
    specify { expect(clef.pitch_for_space(6)).to eq 'D4' }
    specify { expect(clef.pitch_for_line(7)).to eq 'E4' }
  end

  context 'mezzo-soprano clef' do
    let(:name) { 'mezzo-soprano' }

    it { is_expected.not_to be_modern }

    specify { expect(clef.pitch_for_line(2)).to eq 'C4' }
  end

  context 'the tenor clef' do
    context "when constructed with the name 'tenor'" do
      let(:name) { 'tenor' }

      it 'returns to the choral tenor clef' do
        expect(clef.clef_type).to eq 'G-clef'
      end
    end

    context "when constructed with the name 'tenor C-clef'" do
      let(:name) { 'tenor C-clef' }

      it 'returns to the choral tenor clef' do
        expect(clef.clef_type).to eq 'C-clef'
      end
    end
  end

  describe '.get' do
    context 'when given an instance' do
      let(:instance) { described_class.get(:french) }

      it 'returns that instance' do
        expect(described_class.get(instance)).to be instance
      end
    end
  end
end
