require "spec_helper"

describe HeadMusic::Content::Voice::MelodicNotePair do
  subject(:melodic_note_pair) { described_class.new(note_d4, note_e4) }

  let(:voice) { HeadMusic::Content::Voice.new }
  let(:pitch_d4) { HeadMusic::Rudiment::Pitch.get("D4") }
  let(:pitch_e4) { HeadMusic::Rudiment::Pitch.get("E4") }
  let(:pitch_g4) { HeadMusic::Rudiment::Pitch.get("G4") }
  let(:note_d4) { HeadMusic::Content::Note.new("D4", :quarter, voice, "2:1") }
  let(:note_e4) { HeadMusic::Content::Note.new("E4", :quarter, voice, "2:2") }
  let(:note_g4) { HeadMusic::Content::Note.new("G4", :quarter, voice, "2:3") }

  its(:first_note) { is_expected.to eq note_d4 }
  its(:second_note) { is_expected.to eq note_e4 }
  its(:notes) { are_expected.to eq [note_d4, note_e4] }
  its(:pitches) { are_expected.to eq [pitch_d4, pitch_e4] }

  # Delegated methods
  it { is_expected.to be_ascending }
  it { is_expected.not_to be_descending }
  it { is_expected.not_to be_repetition }
  it { is_expected.to be_step }
  it { is_expected.not_to be_leap }
  it { is_expected.not_to be_large_leap }
  it { is_expected.not_to be_octave }
  it { is_expected.not_to be_unison }
  it { is_expected.not_to be_perfect }

  describe "#melodic_interval" do
    subject { melodic_note_pair.melodic_interval }

    it { is_expected.to be_a(HeadMusic::Analysis::MelodicInterval) }
    its(:to_s) { is_expected.to eq "ascending major second" }
  end

  describe "#spells_consonant_triad_with?" do
    let(:note_c4) { HeadMusic::Content::Note.new("C4", :quarter, voice, "1:1") }
    let(:note_e4) { HeadMusic::Content::Note.new("E4", :quarter, voice, "3:1") }
    let(:note_f4) { HeadMusic::Content::Note.new("F4", :quarter, voice, "4:1") }

    context "when the pairs form a consonant triad" do
      let(:first_pair) { described_class.new(note_c4, note_e4) }
      let(:second_pair) { described_class.new(note_e4, note_g4) }

      it "returns true" do
        expect(first_pair.spells_consonant_triad_with?(second_pair)).to be true
      end
    end

    context "when the pairs do not form a consonant triad" do
      let(:first_pair) { described_class.new(note_d4, note_f4) }
      let(:second_pair) { described_class.new(note_f4, note_g4) }

      it "returns false" do
        expect(first_pair.spells_consonant_triad_with?(second_pair)).to be false
      end
    end

    context "when one of the pairs is a step" do
      let(:first_pair) { described_class.new(note_c4, note_d4) }
      let(:second_pair) { described_class.new(note_d4, note_g4) }

      it "returns false" do
        expect(first_pair.spells_consonant_triad_with?(second_pair)).to be false
      end
    end
  end

  describe "#spans?" do
    let(:pitch_eb4) { HeadMusic::Rudiment::Pitch.get("Eb4") }

    it "delegates to melodic_interval" do
      melodic_interval = melodic_note_pair.melodic_interval
      allow(melodic_interval).to receive(:spans?)
      melodic_note_pair.spans?(pitch_eb4)
      expect(melodic_interval).to have_received(:spans?).with(pitch_eb4)
    end
  end
end
