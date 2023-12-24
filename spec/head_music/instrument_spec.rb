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
      its(:default_sounding_transposition) { is_expected.to eq(-7) }
    end

    context "when given a string that matches a key" do
      let(:argument) { described_class.get(:oboe_d_amore) }

      its(:name) { is_expected.to eq "oboe d'amore" }
      its(:default_sounding_transposition) { is_expected.to eq(-3) }
    end
  end

  describe ".all" do
    subject(:instruments) { described_class.all }

    its(:length) { is_expected.to be > 1 }
    its(:first) { is_expected.to be_a described_class }

    it "has structural integrity" do # rubocop:disable RSpec/ExampleLength
      instruments.each do |instrument|
        expect(instrument).to be_a described_class
        expect(instrument.name).to be_a String
        expect(instrument.pitch_configurations).to be_an Array
        expect(instrument.default_clefs).to be_an Array
        instrument.pitch_configurations.each do |pitch_configuration|
          expect(pitch_configuration).to be_a HeadMusic::Instrument::PitchConfiguration
          expect(pitch_configuration.staff_configurations).to be_an Array
          expect(pitch_configuration.staff_configurations).not_to be_empty
          pitch_configuration.staff_configurations.each do |staff_configuration|
            expect(staff_configuration).to be_a HeadMusic::Instrument::StaffConfiguration
            expect(staff_configuration.staves.first.clef).to be_a HeadMusic::Clef
            expect(staff_configuration.staves.first.sounding_transposition).to be_an Integer
          end
          expect(pitch_configuration.staff_configurations.detect(&:default?)).to be_truthy
        end
      end
    end
  end

  context "when piano" do
    subject(:piano) { described_class.get(:piano) }

    before do
      HeadMusic::InstrumentFamily.all
      described_class.all
    end

    its(:name) { is_expected.to eq "piano" }
    its(:default_clefs) { are_expected.to eq %w[treble_clef bass_clef] }
    its(:orchestra_section_key) { are_expected.to eq "keyboard" }
    its(:classification_keys) { are_expected.to include "string" }
    its(:classification_keys) { are_expected.to include "keyboard" }

    specify { expect(piano.translation(:de)).to eq "Piano" }
  end

  context "when organ" do
    subject(:organ) { described_class.get(:organ) }

    its(:name) { is_expected.to eq "organ" }
    its(:default_clefs) { are_expected.to eq %w[treble_clef bass_clef bass_clef] }
    its(:classification_keys) { are_expected.to include "keyboard" }
    it { is_expected.not_to be_transposing }
    it { is_expected.not_to be_single_staff }
    it { is_expected.to be_multiple_staves }
    it { is_expected.to be_pitched }
  end

  context "when violin" do
    subject(:violin) { described_class.get(:violin) }

    its(:name) { is_expected.to eq "violin" }
    its(:default_clefs) { are_expected.to eq ["treble_clef"] }
    its(:classification_keys) { are_expected.to include "string" }
    it { is_expected.to be_pitched }

    specify { expect(violin.translation(:it)).to eq "violino" }
    specify { expect(violin.translation(:ru)).to eq "skripka" }
  end

  context "when basset horn" do
    subject(:basset_horn) { described_class.get(:basset_horn) }

    its(:name) { is_expected.to eq "basset horn" }
    its(:default_clefs) { are_expected.to eq ["treble_clef"] }
    its(:classification_keys) { are_expected.to include "woodwind" }
    its(:default_sounding_transposition) { is_expected.to eq(-7) }
  end

  context "when bass drum" do
    subject(:bass_drum) { described_class.get(:bass_drum) }

    its(:name) { is_expected.to eq "bass drum" }
    its(:default_clefs) { are_expected.to eq [HeadMusic::Clef.get("neutral_clef")] }
    its(:classification_keys) { are_expected.to include "percussion" }
    it { is_expected.not_to be_pitched }
    it { is_expected.not_to be_transposing }
  end

  context "with marimba" do
    subject(:marimba) { described_class.get(:marimba) }

    its(:name) { is_expected.to eq "marimba" }
    its(:default_clefs) { are_expected.to eq %w[treble_clef bass_clef] }
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
    specify { expect(described_class.get("cor anglais")).to be_transposing }

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
