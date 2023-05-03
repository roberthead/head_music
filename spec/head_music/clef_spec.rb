# frozen_string_literal: true

require "spec_helper"

describe HeadMusic::Clef do
  subject(:clef) { described_class.get(name) }

  context "when treble clef" do
    let(:name) { :treble_clef }

    it { is_expected.to be_modern }

    its(:clef_type) { is_expected.to eq "G-clef" }
    its(:unicode) { is_expected.to eq "𝄞" }

    specify { expect(clef.pitch_for_space(-1)).to eq "B3" }
    specify { expect(clef.pitch_for_line(0)).to eq "C4" }
    specify { expect(clef.pitch_for_space(0)).to eq "D4" }

    specify { expect(clef.pitch_for_line(1)).to eq "E4" }
    specify { expect(clef.pitch_for_space(1)).to eq "F4" }
    specify { expect(clef.pitch_for_line(2)).to eq "G4" }
    specify { expect(clef.pitch_for_space(2)).to eq "A4" }
    specify { expect(clef.pitch_for_line(3)).to eq "B4" }
    specify { expect(clef.pitch_for_space(3)).to eq "C5" }
    specify { expect(clef.pitch_for_line(4)).to eq "D5" }
    specify { expect(clef.pitch_for_space(4)).to eq "E5" }
    specify { expect(clef.pitch_for_line(5)).to eq "F5" }

    specify { expect(clef.pitch_for_space(5)).to eq "G5" }
    specify { expect(clef.pitch_for_line(7)).to eq "C6" }

    specify { expect(clef).to eq :treble_clef }
    specify { expect(clef).not_to eq :bass_clef }
  end

  context "when alto clef" do
    let(:name) { :alto_clef }

    it { is_expected.to be_modern }

    its(:clef_type) { is_expected.to eq "C-clef" }
    its(:unicode) { is_expected.to eq "𝄡" }

    specify { expect(clef.pitch_for_space(-1)).to eq "C3" }
    specify { expect(clef.pitch_for_line(0)).to eq "D3" }
    specify { expect(clef.pitch_for_space(0)).to eq "E3" }

    specify { expect(clef.pitch_for_line(1)).to eq "F3" }
    specify { expect(clef.pitch_for_space(1)).to eq "G3" }
    specify { expect(clef.pitch_for_line(2)).to eq "A3" }
    specify { expect(clef.pitch_for_space(2)).to eq "B3" }
    specify { expect(clef.pitch_for_line(3)).to eq "C4" }
    specify { expect(clef.pitch_for_space(3)).to eq "D4" }
    specify { expect(clef.pitch_for_line(4)).to eq "E4" }
    specify { expect(clef.pitch_for_space(4)).to eq "F4" }
    specify { expect(clef.pitch_for_line(5)).to eq "G4" }

    specify { expect(clef.pitch_for_space(5)).to eq "A4" }
    specify { expect(clef.pitch_for_line(7)).to eq "D5" }

    specify { expect(clef).not_to eq :treble_clef }
    specify { expect(clef).to eq :alto_clef }
  end

  context "when bass clef" do
    let(:name) { :bass_clef }

    it { is_expected.to be_modern }

    its(:clef_type) { is_expected.to eq "F-clef" }
    its(:unicode) { is_expected.to eq "𝄢" }

    specify { expect(clef.pitch_for_space(-1)).to eq "D2" }
    specify { expect(clef.pitch_for_line(0)).to eq "E2" }
    specify { expect(clef.pitch_for_space(0)).to eq "F2" }

    specify { expect(clef.pitch_for_line(1)).to eq "G2" }
    specify { expect(clef.pitch_for_space(1)).to eq "A2" }
    specify { expect(clef.pitch_for_line(2)).to eq "B2" }
    specify { expect(clef.pitch_for_space(2)).to eq "C3" }
    specify { expect(clef.pitch_for_line(3)).to eq "D3" }
    specify { expect(clef.pitch_for_space(3)).to eq "E3" }
    specify { expect(clef.pitch_for_line(4)).to eq "F3" }
    specify { expect(clef.pitch_for_space(4)).to eq "G3" }
    specify { expect(clef.pitch_for_line(5)).to eq "A3" }

    specify { expect(clef.pitch_for_space(5)).to eq "B3" }
    specify { expect(clef.pitch_for_line(6)).to eq "C4" }
    specify { expect(clef.pitch_for_space(6)).to eq "D4" }
    specify { expect(clef.pitch_for_line(7)).to eq "E4" }
  end

  context "when mezzo-soprano clef" do
    let(:name) { "mezzo-soprano clef" }

    it { is_expected.not_to be_modern }

    its(:unicode) { is_expected.to eq "𝄡" }

    specify { expect(clef.pitch_for_line(2)).to eq "C4" }
  end

  context "when the tenor clef" do
    context "when constructed with the name 'tenor clef'" do
      let(:name) { "tenor clef" }

      its(:unicode) { is_expected.to eq "𝄠" }
      its(:clef_type) { is_expected.to eq "G-clef" }

      it { is_expected.to eq "choral tenor clef" }
    end

    context "when constructed with the name 'tenor C-clef'" do
      let(:name) { "tenor C-clef" }

      its(:unicode) { is_expected.to eq "𝄡" }

      it "returns the traditional tenor clef" do
        expect(clef.clef_type).to eq "C-clef"
      end
    end
  end

  context "when when the neutral clef" do
    let(:name) { "neutral clef" }

    it { is_expected.to eq described_class.get("percussion clef") }
    it { is_expected.to eq described_class.get("Schlagzeugschlüssel") }
    it { is_expected.not_to eq described_class.get("clé d'ut") }
  end

  describe "constructor" do
    specify do
      expect { described_class.new(:treble_clef) }.to raise_error(NoMethodError)
    end
  end
end
