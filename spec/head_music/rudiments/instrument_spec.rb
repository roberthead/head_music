# frozen_string_literal: true

require "spec_helper"

describe HeadMusic::Instrument do
  describe ".get" do
    context "when given an instance" do
      let(:instance) { described_class.get("guitar") }

      it "returns that instance" do
        expect(described_class.get(instance)).to be instance
      end
    end
  end

  describe ".all" do
    subject { described_class.all }

    its(:length) { is_expected.to be > 1 }
  end

  context "when piano" do
    subject(:piano) { described_class.get(:piano) }

    its(:name) { is_expected.to eq "piano" }
    its(:standard_staves) { are_expected.to eq %w[treble_clef bass_clef] }
    its(:classifications) { are_expected.to include "string" }
    its(:classifications) { are_expected.to include "keyboard" }

    specify { expect(piano.translation(:de)).to eq "Piano" }
  end

  context "when organ" do
    subject(:organ) { described_class.get(:organ) }

    its(:name) { is_expected.to eq "organ" }
    its(:standard_staves) { are_expected.to eq %w[treble_clef bass_clef bass_clef] }
    its(:classifications) { are_expected.to include "keyboard" }
  end

  context "when violin" do
    subject(:violin) { described_class.get(:violin) }

    its(:name) { is_expected.to eq "violin" }
    its(:standard_staves) { are_expected.to eq ["treble_clef"] }
    its(:classifications) { are_expected.to include "string" }

    specify { expect(violin.translation(:it)).to eq "violino" }
    specify { expect(violin.translation(:ru)).to eq "skripka" }
  end

  describe "#translation" do
    context "when the instrument is unknown" do
      subject(:instrument) { described_class.get("floober") }

      it "returns the name" do
        expect(instrument.translation(:fr)).to eq "floober"
      end
    end
  end
end
