# frozen_string_literal: true

require "spec_helper"

describe HeadMusic::Instrument do
  describe ".get" do
    subject(:result) { described_class.get(argument) }

    context "when given an instance" do
      let(:argument) { described_class.get("guitar") }

      it { is_expected.to be argument }
    end

    context "when given a symbol that matches a key" do
      let(:argument) { described_class.get(:cor_anglais) }

      its(:name) { is_expected.to eq "cor anglais" }
      its(:transposition) { is_expected.to eq(-7) }
    end

    context "when given a string that matches a key" do
      let(:argument) { described_class.get(:oboe_d_amore) }

      its(:name) { is_expected.to eq "oboe d'amore" }
      its(:transposition) { is_expected.to eq(-3) }
    end
  end

  describe ".all" do
    subject { described_class.all }

    its(:length) { is_expected.to be > 1 }
    its(:first) { is_expected.to be_a described_class }
  end

  context "when piano" do
    subject(:piano) { described_class.get(:piano) }

    before do
      HeadMusic::InstrumentFamily.all
      described_class.all
    end

    its(:name) { is_expected.to eq "piano" }
    its(:default_clefs) { are_expected.to eq %w[treble bass] }
    its(:orchestra_section_key) { are_expected.to eq "keyboard" }
    its(:classification_keys) { are_expected.to include "string" }
    its(:classification_keys) { are_expected.to include "keyboard" }

    specify { expect(piano.translation(:de)).to eq "Piano" }
  end

  context "when organ" do
    subject(:organ) { described_class.get(:organ) }

    its(:name) { is_expected.to eq "organ" }
    its(:default_clefs) { are_expected.to eq %w[treble bass bass] }
    its(:classification_keys) { are_expected.to include "keyboard" }
    it { is_expected.not_to be_transposing }
    it { is_expected.not_to be_single_staff }
    it { is_expected.to be_multiple_staffs }
    it { is_expected.to be_pitched }
  end

  context "when violin" do
    subject(:violin) { described_class.get(:violin) }

    its(:name) { is_expected.to eq "violin" }
    its(:default_clefs) { are_expected.to eq ["treble"] }
    its(:classification_keys) { are_expected.to include "string" }
    it { is_expected.to be_pitched }

    specify { expect(violin.translation(:it)).to eq "violino" }
    specify { expect(violin.translation(:ru)).to eq "skripka" }
  end

  context "when basset horn" do
    subject(:basset_horn) { described_class.get(:basset_horn) }

    its(:name) { is_expected.to eq "basset horn" }
    its(:default_clefs) { are_expected.to eq ["treble"] }
    its(:classification_keys) { are_expected.to include "woodwind" }
    its(:transposition) { is_expected.to eq(-7) }
  end

  context "when bass drum" do
    subject(:bass_drum) { described_class.get(:bass_drum) }

    its(:name) { is_expected.to eq "bass drum" }
    its(:default_clefs) { are_expected.to eq ["percussion"] }
    its(:classification_keys) { are_expected.to include "percussion" }
    it { is_expected.not_to be_pitched }
    it { is_expected.not_to be_transposing }
  end

  context "marimba" do
    subject(:marimba) { described_class.get(:marimba) }

    its(:name) { is_expected.to eq "marimba" }
    its(:default_clefs) { are_expected.to eq ["treble", "bass"] }
    its(:classification_keys) { are_expected.to include "percussion" }
    it { is_expected.to be_pitched }
    it { is_expected.not_to be_transposing }
  end

  describe "#translation" do
    context "when the instrument is unknown" do
      subject(:instrument) { described_class.get("floober") }

      it "returns the name" do
        expect(instrument.translation(:fr)).to eq "floober"
      end
    end
  end

  describe "#transposing?" do
    specify { expect(described_class.get(:alto_clarinet)).to be_transposing }
    specify { expect(described_class.get("basset horn")).to be_transposing }
    specify { expect(described_class.get("oboe")).not_to be_transposing }
    specify { expect(described_class.get("english_horn")).to be_transposing }

    specify { expect(described_class.get(:great_highland_bagpipe)).to be_transposing }

    specify { expect(described_class.get(:trumpet)).to be_transposing }

    specify { expect(described_class.get(:piano)).not_to be_transposing }
    specify { expect(described_class.get(:organ)).not_to be_transposing }

    specify { expect(described_class.get(:violin)).not_to be_transposing }
    specify { expect(described_class.get(:viola)).not_to be_transposing }
    specify { expect(described_class.get(:cello)).not_to be_transposing }
    specify { expect(described_class.get(:double_bass)).to be_transposing }
    specify { expect(described_class.get(:double_bass)).to be_transposing_at_the_octave }

    specify { expect(described_class.get(:guitar)).to be_transposing }
    specify { expect(described_class.get(:guitar)).to be_transposing_at_the_octave }
    specify { expect(described_class.get(:bass_guitar)).to be_transposing }
    specify { expect(described_class.get(:bass_guitar)).to be_transposing_at_the_octave }
  end
end