# frozen_string_literal: true

require "spec_helper"

describe HeadMusic::Spelling do
  describe ".get" do
    context "when given an instance" do
      let(:instance) { described_class.get("A♯5") }

      it "returns that instance" do
        expect(described_class.get(instance)).to be instance
      end
    end

    context "for 'C'" do
      subject(:spelling) { described_class.get("C") }

      its(:letter_name) { is_expected.to eq "C" }
      its(:sign) { is_expected.to be_nil }
      its(:pitch_class) { is_expected.to eq 0 }
      it { is_expected.to eq "C" }
      it { is_expected.to be_natural }
    end

    context "for 'F♯'" do
      subject(:spelling) { described_class.get("F♯") }

      its(:letter_name) { is_expected.to eq "F" }
      its(:sign) { is_expected.to eq "♯" }
      its(:pitch_class) { is_expected.to eq 6 }
      it { is_expected.to eq "F♯" }
      it { is_expected.to be_sharp }
      it { is_expected.not_to be_flat }
    end

    context "for 'Bb'" do
      subject(:spelling) { described_class.get("Bb") }

      its(:pitch_class) { is_expected.to eq 10 }
      it { is_expected.to eq "Bb" }
      it { is_expected.not_to be_sharp }
      it { is_expected.to be_flat }
    end

    context "for 'Cb'" do
      subject(:spelling) { described_class.get("Cb") }

      its(:pitch_class) { is_expected.to eq 11 }
      it { is_expected.to eq "Cb" }
    end

    context "for 'B♯'" do
      subject(:spelling) { described_class.get("B♯") }

      its(:letter_name) { is_expected.to eq "B" }
      its(:sign) { is_expected.to eq "♯" }
      its(:pitch_class) { is_expected.to eq 0 }
      it { is_expected.to eq "B♯" }
    end

    context "for 'bb'" do
      subject(:spelling) { described_class.get("bb") }

      its(:letter_name) { is_expected.to eq "B" }
      its(:sign) { is_expected.to eq "b" }
      its(:pitch_class) { is_expected.to eq 10 }
      it { is_expected.to eq "Bb" }
    end

    context "for 'Fx'" do
      subject(:spelling) { described_class.get("Fx") }

      its(:letter_name) { is_expected.to eq "F" }
      its(:sign) { is_expected.to eq "x" }
      its(:pitch_class) { is_expected.to eq 7 }

      it { is_expected.not_to be_sharp }
      it { is_expected.not_to be_flat }
      it { is_expected.not_to be_natural }
      it { is_expected.to be_double_sharp }
    end

    context "given a pitch class" do
      subject(:spelling) { described_class.get(HeadMusic::PitchClass.get(3)) }

      its(:pitch_class) { is_expected.to eq 3 }
      it { is_expected.to eq "D♯" }
    end

    context "given a pitch class number" do
      subject(:spelling) { described_class.get(1) }

      its(:pitch_class) { is_expected.to eq 1 }
      it { is_expected.to eq "C♯" }
    end

    context "given the pitch class number for F♯/Gb" do
      subject(:spelling) { described_class.get(6) }

      its(:pitch_class) { is_expected.to eq 6 }
      it { is_expected.to eq "F♯" }
    end
  end

  describe "#scale" do
    context "without an argument" do
      subject(:scale) { described_class.get("D").scale }

      its(:spellings) { are_expected.to eq %w[D E F♯ G A B C♯ D] }
    end

    context "passed a scale type" do
      subject(:scale) { described_class.get("E").scale(:minor) }

      its(:spellings) { are_expected.to eq %w[E F♯ G A B C D E] }
    end
  end

  describe "#letter_name_series_* methods" do
    subject(:spelling) { described_class.get("D") }

    its(:letter_name_series_ascending) { is_expected.to eq %w[D E F G A B C] }
    its(:letter_name_series_descending) { is_expected.to eq %w[D C B A G F E] }
  end

  describe "#enharmonic?" do
    specify { expect(described_class.get("G♯")).to be_enharmonic(described_class.get("Ab")) }
    specify { expect(described_class.get("G♯")).not_to be_enharmonic(described_class.get("G")) }
    specify { expect(described_class.get("G♯")).not_to be_enharmonic(described_class.get("A")) }

    specify { expect(described_class.get("C")).to be_enharmonic(described_class.get("B♯")) }
    specify { expect(described_class.get("B♯")).to be_enharmonic(described_class.get("C")) }
  end
end
