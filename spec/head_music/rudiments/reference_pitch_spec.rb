# frozen_string_literal: true

require "spec_helper"

describe HeadMusic::ReferencePitch do
  it { is_expected.to respond_to(:pitch) }
  it { is_expected.to respond_to(:frequency) }

  describe "constructor" do
    context "when not given any arguments" do
      subject(:tuning) { described_class.new }

      its(:pitch) { is_expected.to eq "A4" }
      its(:frequency) { is_expected.to eq 440.0 }
      its(:description) { is_expected.to eq "A=440" }
      its(:to_s) { is_expected.to eq "A=440" }
    end
  end

  describe ".get" do
    context "when passing 'A440'" do
      subject(:tuning) { described_class.get("A440") }

      its(:pitch) { is_expected.to eq "A4" }
      its(:frequency) { is_expected.to eq 440.0 }
      its(:description) { is_expected.to eq "A=440" }
    end

    context "when passing 'ISO 16'" do
      subject(:tuning) { described_class.get("ISO 16") }

      its(:pitch) { is_expected.to eq "A4" }
      its(:frequency) { is_expected.to eq 440.0 }
      its(:description) { is_expected.to eq "A=440" }
    end

    context "when passing nonsense" do
      subject(:tuning) { described_class.get("pthpthpth") }

      its(:pitch) { is_expected.to eq "A4" }
      its(:frequency) { is_expected.to eq 440.0 }
      its(:description) { is_expected.to eq "A=440" }
    end

    context "when passing 'Scientific'" do
      subject(:tuning) { described_class.get("Scientific") }

      its(:pitch) { is_expected.to eq "C4" }
      its(:frequency) { is_expected.to eq 256.0 }
      its(:description) { is_expected.to eq "C=256" }
    end

    context "when passing 'French'" do
      subject(:tuning) { described_class.get("French") }

      its(:pitch) { is_expected.to eq "A4" }
      its(:frequency) { is_expected.to eq 435.0 }
      its(:description) { is_expected.to eq "A=435" }
    end

    context "when passing :old_philharmonic" do
      subject(:tuning) { described_class.get(:old_philharmonic) }

      its(:pitch) { is_expected.to eq "A4" }
      its(:frequency) { is_expected.to eq 452.4 }
      its(:description) { is_expected.to eq "A=452.4" }
    end
  end
end
