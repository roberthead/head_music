require "spec_helper"

describe HeadMusic::Analysis::MelodicInterval do
  subject(:melodic_interval) { described_class.new(note_d4, note_g4) }

  let(:voice) { HeadMusic::Content::Voice.new }
  let(:note_d4) { HeadMusic::Content::Note.new("D4", :quarter, voice, "2:1") }
  let(:note_g4) { HeadMusic::Content::Note.new("G4", :quarter, voice, "2:3") }

  its(:first_note) { is_expected.to eq note_d4 }
  its(:second_note) { is_expected.to eq note_g4 }

  its(:diatonic_interval) { is_expected.to eq "perfect fourth" }
  its(:position_start) { is_expected.to eq "2:1" }
  its(:position_end) { is_expected.to eq "2:4" }
  its(:notes) { are_expected.to eq [note_d4, note_g4] }
  its(:to_s) { is_expected.to eq "ascending perfect fourth" }

  it { is_expected.to be_moving }
  it { is_expected.to be_ascending }
  it { is_expected.not_to be_descending }
end
