require "spec_helper"

# NOTE: GenericInstrument is now a deprecated facade that delegates to Instrument.
# These tests verify backward compatibility.
describe HeadMusic::Instruments::GenericInstrument do
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

    context "when given a string that does not match a key" do
      let(:argument) { described_class.get("floober") }

      it { is_expected.to be_nil }
    end
  end

  describe ".all" do
    subject(:instruments) { described_class.all }

    its(:length) { is_expected.to be > 1 }
    its(:first) { is_expected.to be_a HeadMusic::Instruments::Instrument }

    it "has structural integrity" do # rubocop:disable RSpec/ExampleLength
      instruments.each do |instrument|
        expect(instrument).to be_a HeadMusic::Instruments::Instrument
        expect(instrument.name).to be_a String
        expect(instrument.staff_schemes).to be_an Array
        expect(instrument.default_clefs).to be_an Array
        next if instrument.staff_schemes.empty?

        instrument.staff_schemes.each do |staff_scheme|
          expect(staff_scheme).to be_a HeadMusic::Instruments::StaffScheme
          expect(staff_scheme.staves.first.clef).to be_a HeadMusic::Rudiment::Clef
          expect(staff_scheme.staves.first.sounding_transposition).to be_an Integer
        end
        expect(instrument.staff_schemes.detect(&:default?)).to be_truthy
      end
    end
  end

  context "when piano" do
    subject(:piano) { described_class.get(:piano) }

    before do
      HeadMusic::Instruments::InstrumentFamily.all
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
    specify { expect(violin.translation(:ru)).to eq "скрипка" }
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
    its(:default_clefs) { are_expected.to eq [HeadMusic::Rudiment::Clef.get("neutral_clef")] }
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
    context "when the instrument exists" do
      subject(:instrument) { described_class.get("piano") }

      it "returns the translation" do
        expect(instrument.translation(:de)).to eq "Piano"
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

  context "when drum_kit" do
    subject(:drum_kit) { described_class.get(:drum_kit) }

    its(:name) { is_expected.to eq "drum kit" }
    its(:default_clefs) { are_expected.to eq [HeadMusic::Rudiment::Clef.get("neutral_clef")] }
    its(:classification_keys) { are_expected.to include "percussion" }
    it { is_expected.not_to be_pitched }
    it { is_expected.not_to be_transposing }

    describe "staff mappings" do
      it "has mappings on its default staff" do
        staff = drum_kit.default_staves.first
        expect(staff.mappings).to be_an(Array)
        expect(staff.mappings).not_to be_empty
        expect(staff.mappings).to all(be_a(HeadMusic::Notation::StaffMapping))
      end

      it "maps standard drum kit positions" do
        staff = drum_kit.default_staves.first
        expect(staff.instrument_for_position(4).name).to eq("snare drum")
        expect(staff.instrument_for_position(0).name).to eq("bass drum")
        expect(staff.instrument_for_position(9).name).to eq("hi hat")
      end

      describe "hi_hat mappings" do
        let(:staff) { drum_kit.default_staves.first }

        it "maps to two different techniques" do
          mappings = staff.mappings.select { |m| m.instrument_key == "hi_hat" }
          expect(mappings.length).to eq(2)
        end

        it "maps pedal technique at position -1" do
          mapping = staff.mapping_for_position(-1)
          expect(mapping.instrument_key).to eq("hi_hat")
          expect(mapping.playing_technique_key).to eq("pedal")
        end

        it "maps stick technique at position 9" do
          mapping = staff.mapping_for_position(9)
          expect(mapping.instrument_key).to eq("hi_hat")
          expect(mapping.playing_technique_key).to eq("stick")
        end
      end

      it "has components derived from mapping" do
        staff = drum_kit.default_staves.first
        components = staff.components
        expect(components.length).to eq(8)
        expect(components.map(&:name)).to include("snare drum", "bass drum", "hi hat")
      end
    end
  end

  context "when hi_hat" do
    subject(:hi_hat) { described_class.get(:hi_hat) }

    its(:name) { is_expected.to eq "hi hat" }
    its(:default_clefs) { are_expected.to eq [HeadMusic::Rudiment::Clef.get("neutral_clef")] }
    its(:classification_keys) { are_expected.to include "percussion" }
    it { is_expected.not_to be_pitched }
    it { is_expected.not_to be_transposing }
  end

  context "when crash_cymbal" do
    subject(:crash_cymbal) { described_class.get(:crash_cymbal) }

    its(:name) { is_expected.to eq "crash cymbal" }
    its(:default_clefs) { are_expected.to eq [HeadMusic::Rudiment::Clef.get("neutral_clef")] }
    its(:classification_keys) { are_expected.to include "percussion" }
    it { is_expected.not_to be_pitched }
    it { is_expected.not_to be_transposing }
  end

  context "when high_tom" do
    subject(:high_tom) { described_class.get(:high_tom) }

    its(:name) { is_expected.to eq "high tom" }
    its(:default_clefs) { are_expected.to eq [HeadMusic::Rudiment::Clef.get("neutral_clef")] }
    its(:classification_keys) { are_expected.to include "percussion" }
    it { is_expected.not_to be_pitched }
    it { is_expected.not_to be_transposing }
  end

  describe "branch coverage for edge cases" do
    context "when instrument does not exist" do
      it "returns nil for unknown instruments" do
        expect(described_class.get("unknown_instrument")).to be_nil
      end
    end

    context "when looking up instruments by translation" do
      it "finds instruments by localized names" do
        piano = described_class.get("Piano") # German translation
        expect(piano.name).to eq("piano")
      end

      it "returns nil for non-existent translations" do
        non_existent = described_class.get("definitely_not_an_instrument_12345")
        expect(non_existent).to be_nil
      end
    end

    context "when testing staff and clef methods" do
      it "handles valid instruments correctly" do
        piano = described_class.get(:piano)
        expect(piano.default_staves).not_to be_empty
        expect(piano.default_clefs).not_to be_empty
        expect(piano.default_sounding_transposition).to eq(0)
      end
    end

    context "when testing initialization paths" do
      it "exercises record_for_key with exact matches" do
        oboe = described_class.get("oboe")
        expect(oboe.name).to eq("oboe")
      end

      it "exercises family inheritance when family exists" do
        violin = described_class.get(:violin)
        expect(violin.orchestra_section_key).not_to be_nil
        expect(violin.classification_keys).not_to be_empty
      end
    end

    context "when testing orchestra_section_key inheritance" do
      it "inherits orchestra_section_key from family" do
        piano = described_class.get(:piano)
        expect(piano.orchestra_section_key).to eq("keyboard")
      end
    end
  end
end
