require "spec_helper"

describe HeadMusic::Instruments::InstrumentType do
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

      it { is_expected.to be_a described_class }
      its(:name) { is_expected.to eq "floober" }
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
        expect(instrument.variants).to be_an Array
        expect(instrument.default_clefs).to be_an Array
        instrument.variants.each do |variant|
          expect(variant).to be_a HeadMusic::Instruments::Variant
          expect(variant.staff_schemes).to be_an Array
          expect(variant.staff_schemes).not_to be_empty
          variant.staff_schemes.each do |staff_scheme|
            expect(staff_scheme).to be_a HeadMusic::Instruments::StaffScheme
            expect(staff_scheme.staves.first.clef).to be_a HeadMusic::Rudiment::Clef
            expect(staff_scheme.staves.first.sounding_transposition).to be_an Integer
          end
          expect(variant.staff_schemes.detect(&:default?)).to be_truthy
        end
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

  describe "branch coverage for edge cases" do
    context "when instrument has no family" do
      subject(:unknown_instrument) { described_class.get("unknown_instrument") }

      it "handles nil family gracefully" do
        expect(unknown_instrument.family).to be_nil
      end

      it "handles translation without name_key" do
        expect(unknown_instrument.translation(:de)).to eq("unknown_instrument")
      end
    end

    context "when looking up instruments by translation" do
      it "finds instruments by localized names" do
        # Test that key_for_name method works with translations
        # This should trigger the locale iteration branch
        piano = described_class.get("Piano") # German translation
        expect(piano.name).to eq("piano")
      end

      it "returns nil for non-existent translations" do
        # This should test the nil return path in key_for_name
        non_existent = described_class.get("definitely_not_an_instrument_12345")
        expect(non_existent.name).to eq("definitely_not_an_instrument_12345")
      end
    end

    context "when testing staff and clef methods" do
      subject(:unknown_instrument) { described_class.get("unknown_with_no_variants") }

      it "handles instruments with no variants or staves" do
        # These should exercise the ||= branches in default methods
        expect(unknown_instrument.default_staves).to eq([])
        expect(unknown_instrument.default_clefs).to eq([])
        expect(unknown_instrument.default_sounding_transposition).to eq(0)
      end

      it "handles default_variant when variants exist" do
        piano = described_class.get(:piano)
        expect(piano.default_variant).to be_a(HeadMusic::Instruments::Variant)
      end

      it "handles default_variant when no variants exist" do
        unknown = described_class.get("no_variants")
        expect(unknown.default_variant).to be_nil
      end
    end

    context "when testing initialization paths" do
      it "exercises record_for_key with exact matches" do
        # This tests the direct key match path
        oboe = described_class.get("oboe")
        expect(oboe.name).to eq("oboe")
      end

      it "exercises inherit_family_attributes when family exists" do
        violin = described_class.get(:violin)
        expect(violin.orchestra_section_key).not_to be_nil
        expect(violin.classification_keys).not_to be_empty
      end

      it "exercises inherit_family_attributes when family is nil" do
        unknown = described_class.get("unknown_family")
        # Should not crash when family is nil
        expect(unknown.orchestra_section_key).to be_nil
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
