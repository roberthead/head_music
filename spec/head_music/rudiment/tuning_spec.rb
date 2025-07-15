require "spec_helper"

RSpec.describe HeadMusic::Rudiment::Tuning do
  it { is_expected.to respond_to(:reference_pitch) }
  it { is_expected.to respond_to(:reference_pitch_pitch) }
  it { is_expected.to respond_to(:reference_pitch_frequency) }

  context "when not given any arguments" do
    subject(:tuning) { described_class.new }

    its(:reference_pitch_pitch) { is_expected.to eq "A4" }
    its(:reference_pitch_frequency) { is_expected.to eq 440.0 }

    describe "#frequency_for" do
      subject { tuning.frequency_for(pitch_name) }

      context "when C4" do
        let(:pitch_name) { "C4" }

        it { is_expected.to be_within(0.1).of(261.6) }
      end

      context "when A3" do
        let(:pitch_name) { "A3" }

        it { is_expected.to be_within(0.01).of(220.0) }
      end

      context "when A5" do
        let(:pitch_name) { "A5" }

        it { is_expected.to be_within(0.01).of(880.0) }
      end

      context "when A0 (lowest note of piano)" do
        let(:pitch_name) { "A0" }

        it { is_expected.to be_within(0.01).of(27.5) }
      end

      context "when C-1 (subsonic frequency)" do
        let(:pitch_name) { "C-1" }

        it { is_expected.to be_within(0.01).of(8.175) }
      end
    end
  end

  context "when passed the baroque name reference pitch" do
    subject(:tuning) { described_class.new(reference_pitch: HeadMusic::Rudiment::ReferencePitch.get("baroque")) }

    its(:reference_pitch_pitch) { is_expected.to eq "A4" }
    its(:reference_pitch_frequency) { is_expected.to eq 415.0 }

    describe "#frequency_for" do
      subject { tuning.frequency_for(pitch_name) }

      context "when C4" do
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

      context "when C4" do
        let(:pitch_name) { "C4" }

        it { is_expected.to be_within(0.001).of(246.76) }
      end
    end
  end

  describe ".get" do
    context "with just intonation" do
      it "returns a JustIntonation instance" do
        tuning = described_class.get(:just_intonation)
        expect(tuning).to be_a(HeadMusic::Rudiment::Tuning::JustIntonation)
      end

      it "accepts alias 'just'" do
        tuning = described_class.get("just")
        expect(tuning).to be_a(HeadMusic::Rudiment::Tuning::JustIntonation)
      end

      it "accepts alias 'ji'" do
        tuning = described_class.get(:ji)
        expect(tuning).to be_a(HeadMusic::Rudiment::Tuning::JustIntonation)
      end
    end

    context "with pythagorean tuning" do
      it "returns a Pythagorean instance" do
        tuning = described_class.get(:pythagorean)
        expect(tuning).to be_a(HeadMusic::Rudiment::Tuning::Pythagorean)
      end

      it "accepts alias 'pythag'" do
        tuning = described_class.get("pythag")
        expect(tuning).to be_a(HeadMusic::Rudiment::Tuning::Pythagorean)
      end
    end

    context "with meantone temperament" do
      it "returns a Meantone instance" do
        tuning = described_class.get(:meantone)
        expect(tuning).to be_a(HeadMusic::Rudiment::Tuning::Meantone)
      end

      it "accepts alias 'quarter_comma_meantone'" do
        tuning = described_class.get("quarter_comma_meantone")
        expect(tuning).to be_a(HeadMusic::Rudiment::Tuning::Meantone)
      end

      it "accepts alias '1/4_comma'" do
        tuning = described_class.get("1/4_comma")
        expect(tuning).to be_a(HeadMusic::Rudiment::Tuning::Meantone)
      end
    end

    context "with equal temperament" do
      it "returns a base Tuning instance by default" do
        tuning = described_class.get
        expect(tuning).to be_a(described_class)
        expect(tuning).not_to be_a(HeadMusic::Rudiment::Tuning::JustIntonation)
      end

      it "returns a base Tuning instance for 'equal_temperament'" do
        tuning = described_class.get(:equal_temperament)
        expect(tuning).to be_a(described_class)
        expect(tuning).not_to be_a(HeadMusic::Rudiment::Tuning::JustIntonation)
      end

      it "accepts alias 'equal'" do
        tuning = described_class.get("equal")
        expect(tuning).to be_a(described_class)
      end

      it "accepts alias 'et'" do
        tuning = described_class.get(:et)
        expect(tuning).to be_a(described_class)
      end

      it "accepts alias '12tet'" do
        tuning = described_class.get("12tet")
        expect(tuning).to be_a(described_class)
      end
    end

    context "with unknown tuning type" do
      it "defaults to equal temperament" do
        tuning = described_class.get(:unknown_type)
        expect(tuning).to be_a(described_class)
        expect(tuning).not_to be_a(HeadMusic::Rudiment::Tuning::JustIntonation)
      end
    end

    context "with options" do
      it "passes options to the tuning constructor" do
        tuning = described_class.get(:just_intonation, reference_pitch: "baroque", tonal_center: "D4")
        expect(tuning.reference_pitch_frequency).to eq(415.0)
        expect(tuning.tonal_center.to_s).to eq("D4")
      end
    end
  end
end
