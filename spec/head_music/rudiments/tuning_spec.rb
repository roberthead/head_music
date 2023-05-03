# frozen_string_literal: true

require "spec_helper"

describe HeadMusic::Tuning do
  it { is_expected.to respond_to(:reference_pitch) }
  it { is_expected.to respond_to(:reference_pitch_pitch) }
  it { is_expected.to respond_to(:reference_pitch_frequency) }

  context "when not given any arguments" do
    subject(:tuning) { described_class.new }

    its(:reference_pitch_pitch) { is_expected.to eq "A4" }
    its(:reference_pitch_frequency) { is_expected.to eq 440.0 }

    describe "#frequency_for" do
      subject { tuning.frequency_for(pitch_name) }

      context "C4" do
        let(:pitch_name) { "C4" }

        it { is_expected.to be_within(0.1).of(261.6) }
      end

      context "A3" do
        let(:pitch_name) { "A3" }

        it { is_expected.to be_within(0.01).of(220.0) }
      end

      context "A5" do
        let(:pitch_name) { "A5" }

        it { is_expected.to be_within(0.01).of(880.0) }
      end

      context "A0 (lowest note of piano)" do
        let(:pitch_name) { "A0" }

        it { is_expected.to be_within(0.01).of(27.5) }
      end

      context "C-1 (subsonic frequency)" do
        let(:pitch_name) { "C-1" }

        it { is_expected.to be_within(0.01).of(8.175) }
      end
    end
  end

  context "when passed the baroque name reference pitch" do
    subject(:tuning) { described_class.new(reference_pitch: HeadMusic::ReferencePitch.get("baroque")) }

    its(:reference_pitch_pitch) { is_expected.to eq "A4" }
    its(:reference_pitch_frequency) { is_expected.to eq 415.0 }

    describe "#frequency_for" do
      subject { tuning.frequency_for(pitch_name) }

      context "C4" do
        let(:pitch_name) { "C4" }

        it { is_expected.to be_within(0.001).of(246.76) }
      end
    end
  end

  context "when passed the name of the baroque reference pitch" do
    subject(:tuning) { described_class.new(reference_pitch: "baroque") }

    its(:reference_pitch_pitch) { is_expected.to eq "A4" }
    its(:reference_pitch_frequency) { is_expected.to eq 415.0 }

    describe "#frequency_for" do
      subject { tuning.frequency_for(pitch_name) }

      context "C4" do
        let(:pitch_name) { "C4" }

        it { is_expected.to be_within(0.001).of(246.76) }
      end
    end
  end
end
