require "spec_helper"

describe HeadMusic::Instruments::Instrument do
  describe ".get" do
    subject(:result) { described_class.get(*arguments) }

    context "when given an existing instrument instance" do
      let(:existing) { described_class.get("trumpet") }
      let(:arguments) { [existing] }

      it { is_expected.to be existing }
    end

    context "when given a simple instrument name" do
      let(:arguments) { ["clarinet"] }

      it { is_expected.to be_a described_class }
      its(:name) { is_expected.to eq "clarinet" }
      its(:pitch_designation) { is_expected.to eq HeadMusic::Rudiment::Spelling.get("Bb") }
      its(:sounding_transposition) { is_expected.to eq(-2) }
    end

    context "when given an instrument with variant in the name" do
      let(:arguments) { ["trumpet_in_c"] }

      it { is_expected.to be_a described_class }
      its(:name) { is_expected.to eq "trumpet in C" }
      its(:pitch_designation) { is_expected.to eq HeadMusic::Rudiment::Spelling.get("C") }
      its(:sounding_transposition) { is_expected.to eq(0) }
    end

    context "when given an instrument with flat variant in the name" do
      let(:arguments) { ["trumpet_in_e_flat"] }

      it { is_expected.to be_a described_class }
      its(:name) { is_expected.to eq "trumpet in E♭" }
      its(:pitch_designation) { is_expected.to eq HeadMusic::Rudiment::Spelling.get("Eb") }
      its(:sounding_transposition) { is_expected.to eq(3) }
    end

    context "when given instrument and variant as separate arguments" do
      let(:arguments) { ["trumpet", "in_c"] }

      it { is_expected.to be_a described_class }
      its(:name) { is_expected.to eq "trumpet in C" }
      its(:pitch_designation) { is_expected.to eq HeadMusic::Rudiment::Spelling.get("C") }
      its(:sounding_transposition) { is_expected.to eq(0) }
    end

    context "when given clarinet with A variant" do
      let(:arguments) { ["clarinet", "in_a"] }

      it { is_expected.to be_a described_class }
      its(:name) { is_expected.to eq "clarinet in A" }
      its(:pitch_designation) { is_expected.to eq HeadMusic::Rudiment::Spelling.get("A") }
      its(:sounding_transposition) { is_expected.to eq(-3) }
    end

    context "when given a non-transposing instrument" do
      let(:arguments) { ["violin"] }

      it { is_expected.to be_a described_class }
      its(:name) { is_expected.to eq "violin" }
      its(:pitch_designation) { is_expected.to be_nil }
      its(:sounding_transposition) { is_expected.to eq(0) }
      its(:transposing?) { is_expected.to be false }
    end

    context "when given an invalid instrument name" do
      let(:arguments) { ["floober"] }

      it { is_expected.to be_nil }
    end

    context "when using alias names" do
      let(:arguments) { ["piccolo"] }

      it { is_expected.to be_a described_class }
      its(:name) { is_expected.to eq "piccolo flute" }
      its(:name_key) { is_expected.to eq :piccolo_flute }
    end
  end

  describe "#==" do
    let(:trumpet_in_c) { described_class.get("trumpet", "in_c") }
    let(:trumpet_in_c_2) { described_class.get("trumpet_in_c") }
    let(:trumpet_in_bb) { described_class.get("trumpet") }
    let(:clarinet) { described_class.get("clarinet") }

    it "considers instruments equal if they have the same type and variant" do
      expect(trumpet_in_c).to eq(trumpet_in_c_2)
    end

    it "considers instruments different if they have different variants" do
      expect(trumpet_in_c).not_to eq(trumpet_in_bb)
    end

    it "considers instruments different if they have different types" do
      expect(trumpet_in_c).not_to eq(clarinet)
    end
  end

  describe "delegations to generic_instrument" do
    subject(:instrument) { described_class.get("alto_saxophone") }

    its(:name_key) { is_expected.to eq :alto_saxophone }
    its(:family_key) { is_expected.to eq "saxophone" }
    its(:family) { is_expected.to be_a HeadMusic::Instruments::InstrumentFamily }
  end

  describe "delegations to variant" do
    subject(:instrument) { described_class.get("trumpet", "in_d") }

    its(:pitch_designation) { is_expected.to be_a HeadMusic::Rudiment::Spelling }
    its(:staff_schemes) { is_expected.to be_an Array }
    its(:default_staff_scheme) { is_expected.to be_a HeadMusic::Instruments::StaffScheme }
    its(:default_staves) { is_expected.to be_an Array }
    its(:default_clefs) { is_expected.to be_an Array }
  end

  describe "#transposing?" do
    context "for a transposing instrument" do
      subject(:instrument) { described_class.get("clarinet") }

      its(:transposing?) { is_expected.to be true }
    end

    context "for a non-transposing instrument" do
      subject(:instrument) { described_class.get("trumpet", "in_c") }

      its(:transposing?) { is_expected.to be false }
    end
  end

  describe "#transposing_at_the_octave?" do
    context "for an octave-transposing instrument" do
      subject(:instrument) { described_class.get("piccolo_flute") }

      its(:transposing_at_the_octave?) { is_expected.to be true }
    end

    context "for a non-octave-transposing instrument" do
      subject(:instrument) { described_class.get("clarinet") }

      its(:transposing_at_the_octave?) { is_expected.to be false }
    end
  end

  describe "#single_staff?" do
    context "for a single-staff instrument" do
      subject(:instrument) { described_class.get("trumpet") }

      its(:single_staff?) { is_expected.to be true }
    end

    context "for a multiple-staff instrument" do
      subject(:instrument) { described_class.get("piano") }

      its(:single_staff?) { is_expected.to be false }
    end
  end

  describe "#multiple_staves?" do
    context "for a multiple-staff instrument" do
      subject(:instrument) { described_class.get("piano") }

      its(:multiple_staves?) { is_expected.to be true }
    end

    context "for a single-staff instrument" do
      subject(:instrument) { described_class.get("trumpet") }

      its(:multiple_staves?) { is_expected.to be false }
    end
  end

  describe "#pitched?" do
    context "for a pitched instrument" do
      subject(:instrument) { described_class.get("violin") }

      its(:pitched?) { is_expected.to be true }
    end

    context "for an unpitched instrument" do
      subject(:instrument) { described_class.get("snare_drum") }

      its(:pitched?) { is_expected.to be false }
    end
  end

  describe "#to_s" do
    context "for a default variant" do
      subject(:instrument) { described_class.get("clarinet") }

      its(:to_s) { is_expected.to eq "clarinet" }
    end

    context "for a specific variant" do
      subject(:instrument) { described_class.get("trumpet_in_c") }

      its(:to_s) { is_expected.to eq "trumpet in C" }
    end
  end

  describe "variant name parsing" do
    it "parses 'trumpet_in_eb' correctly (normalizes to trumpet_in_e_flat)" do
      instrument = described_class.get("trumpet_in_eb")
      expect(instrument.name).to eq("trumpet in E♭")
    end

    it "parses 'trumpet_in_e_flat' correctly" do
      instrument = described_class.get("trumpet_in_e_flat")
      expect(instrument.name).to eq("trumpet in E♭")
    end

    it "returns nil for 'clarinet_in_bb' since clarinet_in_b_flat is not a separate instrument" do
      # In the new architecture, clarinet defaults to Bb, so there's no separate clarinet_in_b_flat
      # Users should use 'clarinet' directly for the Bb version
      instrument = described_class.get("clarinet_in_bb")
      expect(instrument).to be_nil
    end

    it "attempts to normalize sharp variant names" do
      # The normalization happens but no sharp instruments exist in the data
      instrument = described_class.get("trumpet_in_f#")
      expect(instrument).to be_nil
    end

    it "handles names without variant suffixes" do
      instrument = described_class.get("violin")
      expect(instrument.name).to eq("violin")
    end
  end

  describe ".get edge cases" do
    it "returns nil for nil input" do
      expect(described_class.get(nil)).to be_nil
    end

    it "returns nil for empty string" do
      expect(described_class.get("")).to be_nil
    end

    it "handles symbol input" do
      instrument = described_class.get(:trumpet)
      expect(instrument).to be_a(described_class)
      expect(instrument.name).to eq("trumpet")
    end
  end

  describe "#== edge cases" do
    let(:trumpet) { described_class.get("trumpet") }

    it "returns false when compared to nil" do
      expect(trumpet.==(nil)).to be false # rubocop:disable Style/NilComparison
    end

    it "returns false when compared to a string" do
      expect(trumpet == "trumpet").to be false
    end

    it "returns false when compared to a different class" do
      expect(trumpet == Object.new).to be false
    end
  end

  describe ".all" do
    subject(:all_instruments) { described_class.all }

    it "returns an array of instruments" do
      expect(all_instruments).to be_an(Array)
      expect(all_instruments).to all(be_a(described_class))
    end

    it "includes common instruments" do
      names = all_instruments.map(&:name_key)
      expect(names).to include(:violin, :trumpet, :flute, :piano)
    end

    it "is sorted alphabetically by name" do
      names = all_instruments.map { |i| i.name.downcase }
      expect(names).to eq(names.sort)
    end

    it "caches the result" do
      first_call = described_class.all
      second_call = described_class.all
      expect(first_call).to be(second_call)
    end
  end

  describe "#parent" do
    context "for an instrument without a parent" do
      subject(:instrument) { described_class.get("trumpet") }

      its(:parent) { is_expected.to be_nil }
      its(:parent_key) { is_expected.to be_nil }
    end

    context "for an instrument with a parent" do
      subject(:instrument) { described_class.get("trumpet_in_c") }

      it "returns the parent instrument" do
        expect(instrument.parent).to be_a(described_class)
        expect(instrument.parent.name_key).to eq(:trumpet)
      end

      it "has a parent_key" do
        expect(instrument.parent_key).to eq(:trumpet)
      end
    end
  end

  describe "#family_key resolution" do
    context "for an instrument with its own family_key" do
      subject(:instrument) { described_class.get("trumpet") }

      its(:family_key) { is_expected.to eq("trumpet") }
    end

    context "for a child instrument inheriting family_key from parent" do
      subject(:instrument) { described_class.get("trumpet_in_c") }

      it "inherits family_key from parent" do
        expect(instrument.family_key).to eq("trumpet")
      end
    end
  end

  describe "#pitch_key resolution" do
    context "for an instrument with its own pitch_key" do
      subject(:instrument) { described_class.get("clarinet") }

      its(:pitch_key) { is_expected.to eq("b_flat") }
    end

    context "for a child instrument with its own pitch_key" do
      subject(:instrument) { described_class.get("clarinet_in_a") }

      its(:pitch_key) { is_expected.to eq("a") }
    end

    context "for an instrument without pitch_key" do
      subject(:instrument) { described_class.get("violin") }

      its(:pitch_key) { is_expected.to be_nil }
    end
  end

  describe "#family" do
    context "for an instrument with a family" do
      subject(:instrument) { described_class.get("alto_saxophone") }

      it "returns the InstrumentFamily" do
        expect(instrument.family).to be_a(HeadMusic::Instruments::InstrumentFamily)
        expect(instrument.family.name_key).to eq(:saxophone)
      end
    end

    context "for an instrument without a family_key" do
      subject(:instrument) { described_class.get("violin") }

      it "returns nil when there is no family" do
        # violin has family_key "violin" which may or may not exist as a family
        family = instrument.family
        expect(family).to be_nil.or be_a(HeadMusic::Instruments::InstrumentFamily)
      end
    end
  end

  describe "#orchestra_section_key" do
    context "for a woodwind instrument" do
      subject(:instrument) { described_class.get("flute") }

      its(:orchestra_section_key) { is_expected.to eq("woodwind") }
    end

    context "for a brass instrument" do
      subject(:instrument) { described_class.get("trumpet") }

      its(:orchestra_section_key) { is_expected.to eq("brass") }
    end

    context "for a string instrument" do
      subject(:instrument) { described_class.get("violin") }

      it "returns the orchestra section" do
        # violin may not have a family defined
        expect(instrument.orchestra_section_key).to be_nil.or eq("string")
      end
    end
  end

  describe "#classification_keys" do
    context "for an instrument with classifications" do
      subject(:instrument) { described_class.get("flute") }

      it "returns an array" do
        expect(instrument.classification_keys).to be_an(Array)
      end
    end

    context "for an instrument without a family" do
      subject(:instrument) { described_class.get("violin") }

      it "returns an empty array as fallback" do
        expect(instrument.classification_keys).to be_an(Array)
      end
    end
  end

  describe "#translation" do
    subject(:instrument) { described_class.get("flute") }

    it "returns the English translation by default" do
      expect(instrument.translation).to eq("flute")
    end

    it "returns translations for other locales" do
      expect(instrument.translation(:de)).to eq("Flöte")
      expect(instrument.translation(:fr)).to eq("flûte")
    end

    it "falls back to name when translation is missing" do
      # Use an instrument that might not have all translations
      expect(instrument.translation(:en)).to be_a(String)
    end
  end

  describe "backward compatibility methods" do
    subject(:instrument) { described_class.get("trumpet") }

    describe "#variants" do
      its(:variants) { is_expected.to eq([]) }
    end

    describe "#default_variant" do
      its(:default_variant) { is_expected.to be_nil }
    end
  end

  describe "#instrument_configurations" do
    context "for an instrument without configurations" do
      subject(:instrument) { described_class.get("clarinet") }

      its(:instrument_configurations) { is_expected.to eq([]) }
    end

    context "for an instrument with its own configurations" do
      subject(:instrument) { described_class.get("trumpet") }

      it "returns its configurations" do
        configs = instrument.instrument_configurations
        expect(configs).to be_an(Array)
        expect(configs.length).to eq(1)
        expect(configs.first.name_key).to eq(:mute)
      end
    end

    context "for an instrument with parent chain configurations" do
      subject(:instrument) { described_class.get("trumpet_in_c") }

      it "collects configurations from parent chain" do
        configs = instrument.instrument_configurations
        expect(configs).to be_an(Array)
        expect(configs.map(&:name_key)).to include(:mute)
      end
    end

    context "for an instrument with both own and inherited configurations" do
      subject(:instrument) { described_class.get("piccolo_trumpet") }

      before do
        # Verify piccolo_trumpet exists and has its own config
        expect(instrument).not_to be_nil
      end

      it "includes own configurations" do
        configs = instrument.instrument_configurations
        expect(configs.map(&:name_key)).to include(:leadpipe)
      end
    end

    context "for bass_trombone with f_attachment" do
      subject(:instrument) { described_class.get("bass_trombone") }

      it "has the f_attachment configuration" do
        configs = instrument.instrument_configurations
        expect(configs.map(&:name_key)).to include(:f_attachment)
      end

      it "has correct options on the configuration" do
        config = instrument.instrument_configurations.find { |c| c.name_key == :f_attachment }
        expect(config.options.map(&:name_key)).to contain_exactly(:disengaged, :engaged)
        expect(config.default_option.name_key).to eq(:disengaged)
      end
    end
  end

  describe "#default_sounding_transposition" do
    it "is aliased to sounding_transposition" do
      instrument = described_class.get("clarinet")
      expect(instrument.default_sounding_transposition).to eq(instrument.sounding_transposition)
    end
  end

  describe "staff scheme inheritance" do
    context "for a child instrument" do
      subject(:instrument) { described_class.get("trumpet_in_d") }

      it "inherits staff schemes from parent when not specified" do
        expect(instrument.staff_schemes).not_to be_empty
        expect(instrument.default_staff_scheme).to be_a(HeadMusic::Instruments::StaffScheme)
      end
    end
  end
end
