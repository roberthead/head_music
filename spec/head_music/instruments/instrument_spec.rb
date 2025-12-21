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
  end
end
