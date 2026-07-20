require "spec_helper"

describe HeadMusic::Analysis::ChordAnalysis do
  subject(:analysis) { described_class.new(collection) }

  let(:collection) { HeadMusic::Analysis::PitchCollection.new(pitches) }

  context "with a root-position major triad" do
    let(:pitches) { %w[C4 E4 G4] }

    it { expect(analysis).to be_tertian }
    it { expect(analysis).to be_triad }
    it { expect(analysis).to be_major_triad }
    it { expect(analysis).to be_consonant_triad }
    it { expect(analysis).to be_root_position_triad }
  end

  context "with a first-inversion major triad" do
    let(:pitches) { %w[E4 G4 C5] }

    it { expect(analysis).to be_triad }
    it { expect(analysis).to be_first_inversion_triad }
    it { expect(analysis).not_to be_root_position_triad }
  end

  context "with a dominant seventh chord" do
    let(:pitches) { %w[G4 B4 D5 F5] }

    it { expect(analysis).to be_seventh_chord }
    it { expect(analysis).to be_root_position_seventh_chord }
    it { expect(analysis).not_to be_triad }
  end

  context "with a non-tertian collection" do
    let(:pitches) { %w[C4 D4 E4] }

    it { expect(analysis).not_to be_tertian }
    it { expect(analysis).not_to be_triad }
  end
end
