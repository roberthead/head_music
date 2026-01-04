require "spec_helper"

describe HeadMusic::Instruments::InstrumentConfigurationOption do
  describe "initialization" do
    subject(:option) { described_class.new(name_key: "a", default: true, transposition_semitones: -1) }

    its(:name_key) { is_expected.to eq :a }
    its(:default) { is_expected.to be true }
    its(:transposition_semitones) { is_expected.to eq(-1) }
    its(:lowest_pitch_semitones) { is_expected.to be_nil }
  end

  describe "#default?" do
    context "when default is true" do
      subject { described_class.new(name_key: "b_flat", default: true) }

      it { is_expected.to be_default }
    end

    context "when default is false" do
      subject { described_class.new(name_key: "a", default: false) }

      it { is_expected.not_to be_default }
    end

    context "when default is not specified" do
      subject { described_class.new(name_key: "a") }

      it { is_expected.not_to be_default }
    end
  end

  describe "#affects_transposition?" do
    context "when transposition_semitones is set" do
      subject { described_class.new(name_key: "a", transposition_semitones: -1) }

      it { is_expected.to be_affects_transposition }
    end

    context "when transposition_semitones is nil" do
      subject { described_class.new(name_key: "open") }

      it { is_expected.not_to be_affects_transposition }
    end
  end

  describe "#affects_range?" do
    context "when lowest_pitch_semitones is set" do
      subject { described_class.new(name_key: "engaged", lowest_pitch_semitones: -6) }

      it { is_expected.to be_affects_range }
    end

    context "when lowest_pitch_semitones is nil" do
      subject { described_class.new(name_key: "disengaged") }

      it { is_expected.not_to be_affects_range }
    end
  end

  describe "#==" do
    let(:a_option) { described_class.new(name_key: "a") }
    let(:b_flat_option) { described_class.new(name_key: "b_flat") }

    it "returns true for options with the same name_key" do
      expect(a_option).to eq described_class.new(name_key: "a")
    end

    it "returns false for options with different name_keys" do
      expect(a_option).not_to eq b_flat_option
    end

    it "returns true when comparing to a non-InstrumentConfigurationOption that resolves to the same name_key" do
      expect(a_option).to eq "a"
      expect(a_option).to eq :a
    end
  end

  describe "#to_s" do
    subject { described_class.new(name_key: "harmon") }

    its(:to_s) { is_expected.to eq "harmon" }
  end
end
