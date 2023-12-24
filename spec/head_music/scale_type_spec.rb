require "spec_helper"

describe HeadMusic::ScaleType do
  describe ".get" do
    context "when given an instance" do
      let(:instance) { described_class.get(:major) }

      it "returns that instance" do
        expect(described_class.get(instance)).to be instance
      end
    end

    context "when given a string" do
      subject(:instance) { described_class.get("Minor") }

      it { is_expected.to eq described_class.minor }
    end
  end

  describe ".new" do
    it "is public" do
      expect { described_class.new(:monotonic, ascending: [12]) }.not_to raise_error
    end
  end

  describe ".melodic_minor" do
    subject(:melodic_minor) { described_class.melodic_minor }

    its(:ascending_intervals) { are_expected.to eq [2, 1, 2, 2, 2, 2, 1] }
    its(:descending_intervals) { are_expected.not_to eq melodic_minor.ascending_intervals.reverse }
    its(:descending_intervals) { are_expected.to eq [2, 2, 1, 2, 2, 1, 2] }
  end

  %i[ionian dorian phrygian lydian mixolydian aeolian locrian].each do |mode|
    describe "#{mode} mode" do
      subject(:scale_type) { described_class.send(mode) }

      its(:descending_intervals) { are_expected.to eq scale_type.ascending_intervals.reverse }

      it "consists entirely of whole and half steps" do
        expect(scale_type.ascending_intervals.uniq.sort).to eq [1, 2]
      end

      its(:name) { is_expected.to eq mode }
      its(:to_s) { is_expected.to eq mode.to_s }

      it { is_expected.to be_diatonic }
      it { is_expected.not_to be_whole_tone }
      it { is_expected.not_to be_pentatonic }
      it { is_expected.not_to be_chromatic }
    end
  end

  describe ".major" do
    subject(:major) { described_class.major }

    its(:ascending_intervals) { are_expected.to eq [2, 2, 1, 2, 2, 2, 1] }
    its(:descending_intervals) { are_expected.to eq major.ascending_intervals.reverse }

    it { is_expected.to eq described_class.ionian }
    it { is_expected.to be_diatonic }
    it { is_expected.not_to be_whole_tone }
    it { is_expected.not_to be_pentatonic }
    it { is_expected.not_to be_chromatic }
  end

  describe ".dorian" do
    subject(:dorian) { described_class.dorian }

    its(:ascending_intervals) { are_expected.to eq [2, 1, 2, 2, 2, 1, 2] }
    its(:descending_intervals) { are_expected.to eq dorian.ascending_intervals.reverse }

    it { is_expected.to be_diatonic }
    it { is_expected.not_to be_whole_tone }
    it { is_expected.not_to be_pentatonic }
    it { is_expected.not_to be_chromatic }
  end

  describe ".whole_tone" do
    subject(:whole_tone) { described_class.whole_tone }

    its(:ascending_intervals) { are_expected.to eq [2, 2, 2, 2, 2, 2] }
    its(:descending_intervals) { are_expected.to eq whole_tone.ascending_intervals }

    it { is_expected.not_to be_diatonic }
    it { is_expected.to be_whole_tone }
    it { is_expected.not_to be_pentatonic }
    it { is_expected.not_to be_chromatic }
  end

  describe ".minor_pentatonic" do
    subject(:minor_pentatonic) { described_class.minor_pentatonic }

    its(:ascending_intervals) { are_expected.to eq [3, 2, 2, 3, 2] }
    its(:descending_intervals) { are_expected.to eq minor_pentatonic.ascending_intervals.reverse }
    its(:parent) { is_expected.to eq described_class.minor }

    it { is_expected.not_to be_diatonic }
    it { is_expected.not_to be_whole_tone }
    it { is_expected.to be_pentatonic }
    it { is_expected.not_to be_chromatic }
  end

  describe ".major_pentatonic" do
    subject(:major_pentatonic) { described_class.major_pentatonic }

    its(:ascending_intervals) { are_expected.to eq [2, 2, 3, 2, 3] }
    its(:descending_intervals) { are_expected.to eq major_pentatonic.ascending_intervals.reverse }
    its(:parent) { is_expected.to eq described_class.major }

    it { is_expected.not_to be_diatonic }
    it { is_expected.not_to be_whole_tone }
    it { is_expected.to be_pentatonic }
    it { is_expected.not_to be_chromatic }
  end

  describe ".chromatic" do
    subject(:chromatic) { described_class.chromatic }

    its(:ascending_intervals) { are_expected.to eq [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1] }
    its(:descending_intervals) { are_expected.to eq chromatic.ascending_intervals }
    its(:parent) { is_expected.to be_nil }

    it { is_expected.not_to be_diatonic }
    it { is_expected.not_to be_whole_tone }
    it { is_expected.not_to be_pentatonic }
    it { is_expected.to be_chromatic }
  end

  describe "equality" do
    specify { expect(described_class.natural_minor).to eq described_class.aeolian }
    specify { expect(described_class.natural_minor).not_to eq described_class.harmonic_minor }
    specify { expect(described_class.natural_minor).not_to eq described_class.melodic_minor }
    specify { expect(described_class.harmonic_minor).not_to eq described_class.melodic_minor }
  end
end
