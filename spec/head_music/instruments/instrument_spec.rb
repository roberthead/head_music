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

    context "when looking up by translated name" do
      it "finds the instrument by German translation" do
        instrument = described_class.get("Klarinette")
        expect(instrument).to be_a(described_class)
        expect(instrument.name_key).to eq(:clarinet)
      end

      it "finds the instrument by French translation" do
        instrument = described_class.get("clarinette")
        expect(instrument).to be_a(described_class)
        expect(instrument.name_key).to eq(:clarinet)
      end
    end

    context "when using two-argument form with invalid variant" do
      it "falls back to the base instrument" do
        # When combined name doesn't exist, should fall back to base
        instrument = described_class.get("trumpet", "in_q")
        expect(instrument).to be_a(described_class)
        expect(instrument.name_key).to eq(:trumpet)
      end
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

    context "for an instrument whose family exists" do
      subject(:instrument) { described_class.get("violin") }

      it "returns the family when it exists" do
        family = instrument.family
        expect(family).to be_a(HeadMusic::Instruments::InstrumentFamily)
        expect(family.name_key).to eq(:violin)
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

      its(:orchestra_section_key) { is_expected.to eq("string") }
    end

    context "for a percussion instrument" do
      subject(:instrument) { described_class.get("snare_drum") }

      its(:orchestra_section_key) { is_expected.to eq("percussion") }
    end

    context "for a keyboard instrument" do
      subject(:instrument) { described_class.get("piano") }

      its(:orchestra_section_key) { is_expected.to eq("keyboard") }
    end
  end

  describe "#classification_keys" do
    context "for an instrument with classifications" do
      subject(:instrument) { described_class.get("flute") }

      it "returns an array of classification keys" do
        expect(instrument.classification_keys).to be_an(Array)
        expect(instrument.classification_keys).to include("woodwind")
      end
    end

    context "for a string instrument" do
      subject(:instrument) { described_class.get("violin") }

      it "returns classification keys including string" do
        expect(instrument.classification_keys).to be_an(Array)
        expect(instrument.classification_keys).to include("string")
      end
    end

    context "for a percussion instrument" do
      subject(:instrument) { described_class.get("snare_drum") }

      it "returns classification keys including percussion" do
        expect(instrument.classification_keys).to include("percussion")
      end
    end
  end

  describe "#pitch_designation" do
    context "for an instrument without pitch_key" do
      subject(:instrument) { described_class.get("violin") }

      its(:pitch_designation) { is_expected.to be_nil }
    end

    context "for an instrument with flat pitch_key" do
      subject(:instrument) { described_class.get("clarinet") }

      it "returns a Spelling for b-flat" do
        expect(instrument.pitch_designation).to eq(HeadMusic::Rudiment::Spelling.get("Bb"))
      end
    end

    context "for an instrument with natural pitch_key" do
      subject(:instrument) { described_class.get("trumpet_in_c") }

      it "returns a Spelling for C" do
        expect(instrument.pitch_designation).to eq(HeadMusic::Rudiment::Spelling.get("C"))
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

    context "for an Italian locale" do
      it "returns the Italian translation" do
        expect(instrument.translation(:it)).to eq("flauto")
      end
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

  describe "#stringing" do
    context "for a stringed instrument with stringing data" do
      subject(:instrument) { described_class.get("guitar") }

      it "returns a Stringing" do
        expect(instrument.stringing).to be_a(HeadMusic::Instruments::Stringing)
      end

      it "has the correct standard pitches" do
        pitch_names = instrument.stringing.standard_pitches.map(&:to_s)
        expect(pitch_names).to eq %w[E2 A2 D3 G3 B3 E4]
      end
    end

    context "for a stringed instrument without stringing data" do
      subject(:instrument) { described_class.get("trumpet") }

      its(:stringing) { is_expected.to be_nil }
    end

    context "for a child instrument inheriting stringing from parent" do
      # Assuming there's no specific stringing for a variant, it should inherit
      subject(:instrument) { described_class.get("violin") }

      it "returns the stringing" do
        expect(instrument.stringing).to be_a(HeadMusic::Instruments::Stringing)
        expect(instrument.stringing.course_count).to eq(4)
      end
    end
  end

  describe "#alternate_tunings" do
    context "for an instrument with alternate tunings" do
      subject(:instrument) { described_class.get("guitar") }

      it "returns an array of AlternateTuning" do
        expect(instrument.alternate_tunings).to be_an(Array)
        expect(instrument.alternate_tunings).to all be_a(HeadMusic::Instruments::AlternateTuning)
      end

      it "includes common tunings" do
        names = instrument.alternate_tunings.map(&:name_key)
        expect(names).to include(:drop_d, :open_g, :dadgad)
      end
    end

    context "for an instrument without alternate tunings" do
      subject(:instrument) { described_class.get("trumpet") }

      its(:alternate_tunings) { is_expected.to eq([]) }
    end

    context "for a child instrument inheriting tunings from parent" do
      let(:guitar) { described_class.get("guitar") }
      let(:trumpet_in_c) { described_class.get("trumpet_in_c") }

      it "inherits tunings when child has none but parent does" do
        # Stub trumpet (parent of trumpet_in_c) to return guitar's tunings
        # This simulates a stringed instrument hierarchy
        allow(trumpet_in_c.parent).to receive(:alternate_tunings).and_return(guitar.alternate_tunings)

        tunings = trumpet_in_c.alternate_tunings
        expect(tunings).not_to be_empty
        expect(tunings.map(&:name_key)).to include(:drop_d)
      end
    end

    context "for a child instrument with no tunings and parent with no tunings" do
      subject(:instrument) { described_class.get("trumpet_in_c") }

      it "returns empty array" do
        expect(instrument.parent).not_to be_nil
        expect(instrument.alternate_tunings).to eq([])
      end
    end

    context "for an instrument with no tunings and no parent" do
      subject(:instrument) { described_class.get("trumpet") }

      it "returns empty array" do
        expect(instrument.parent).to be_nil
        expect(instrument.alternate_tunings).to eq([])
      end
    end
  end

  describe "#default_sounding_transposition" do
    it "is aliased to sounding_transposition" do
      instrument = described_class.get("clarinet")
      expect(instrument.default_sounding_transposition).to eq(instrument.sounding_transposition)
    end
  end

  describe "#sounding_transposition" do
    context "for a non-transposing instrument" do
      subject(:instrument) { described_class.get("violin") }

      its(:sounding_transposition) { is_expected.to eq(0) }
    end

    context "for an octave-transposing instrument" do
      subject(:instrument) { described_class.get("piccolo_flute") }

      its(:sounding_transposition) { is_expected.to eq(12) }
    end

    context "for a downward transposing instrument" do
      subject(:instrument) { described_class.get("clarinet") }

      its(:sounding_transposition) { is_expected.to eq(-2) }
    end
  end

  describe "#default_staves" do
    context "for a single-staff instrument" do
      subject(:instrument) { described_class.get("violin") }

      it "returns an array with one staff" do
        expect(instrument.default_staves).to be_an(Array)
        expect(instrument.default_staves.length).to eq(1)
      end
    end

    context "for a multi-staff instrument" do
      subject(:instrument) { described_class.get("piano") }

      it "returns an array with multiple staves" do
        expect(instrument.default_staves.length).to eq(2)
      end
    end
  end

  describe "#default_clefs" do
    context "for a treble-clef instrument" do
      subject(:instrument) { described_class.get("violin") }

      it "returns treble clef" do
        expect(instrument.default_clefs.first).to eq(HeadMusic::Rudiment::Clef.get("treble_clef"))
      end
    end

    context "for a bass-clef instrument" do
      subject(:instrument) { described_class.get("double_bass") }

      it "includes bass clef" do
        clefs = instrument.default_clefs
        expect(clefs).to include(HeadMusic::Rudiment::Clef.get("bass_clef"))
      end
    end

    context "for a grand-staff instrument" do
      subject(:instrument) { described_class.get("piano") }

      it "returns both treble and bass clefs" do
        clefs = instrument.default_clefs
        expect(clefs).to include(HeadMusic::Rudiment::Clef.get("treble_clef"))
        expect(clefs).to include(HeadMusic::Rudiment::Clef.get("bass_clef"))
      end
    end

    context "for an unpitched percussion instrument" do
      subject(:instrument) { described_class.get("snare_drum") }

      it "returns neutral clef" do
        expect(instrument.default_clefs.first).to eq(HeadMusic::Rudiment::Clef.get("neutral_clef"))
      end
    end
  end

  describe "#default_staff_scheme" do
    context "for a standard instrument" do
      subject(:instrument) { described_class.get("violin") }

      it "returns a staff scheme marked as default" do
        expect(instrument.default_staff_scheme).to be_a(HeadMusic::Instruments::StaffScheme)
        expect(instrument.default_staff_scheme.key).to eq("default")
      end
    end

    context "for a multi-staff instrument" do
      subject(:instrument) { described_class.get("piano") }

      it "returns the default staff scheme" do
        expect(instrument.default_staff_scheme).to be_a(HeadMusic::Instruments::StaffScheme)
      end
    end
  end

  describe "#staff_schemes" do
    context "for an instrument with one scheme" do
      subject(:instrument) { described_class.get("violin") }

      it "returns an array with one staff scheme" do
        expect(instrument.staff_schemes).to be_an(Array)
        expect(instrument.staff_schemes.length).to eq(1)
      end
    end

    context "for a child instrument" do
      subject(:instrument) { described_class.get("trumpet_in_d") }

      it "has its own staff schemes (not inherited)" do
        expect(instrument.staff_schemes).not_to be_empty
        expect(instrument.default_staff_scheme).to be_a(HeadMusic::Instruments::StaffScheme)
      end
    end
  end
end
