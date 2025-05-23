require "spec_helper"

describe HeadMusic::Analysis::MelodicInterval do
  subject(:melodic_interval) { described_class.new(note_d4, note_g4) }

  let(:voice) { HeadMusic::Content::Voice.new }
  let(:pitch_d4) { HeadMusic::Rudiment::Pitch.get("D4") }
  let(:pitch_g4) { HeadMusic::Rudiment::Pitch.get("G4") }
  let(:note_d4) { HeadMusic::Content::Note.new("D4", :quarter, voice, "2:1") }
  let(:note_g4) { HeadMusic::Content::Note.new("G4", :quarter, voice, "2:3") }

  its(:first_pitch) { is_expected.to eq pitch_d4 }
  its(:second_pitch) { is_expected.to eq pitch_g4 }
  its(:pitches) { are_expected.to eq [pitch_d4, pitch_g4] }

  its(:diatonic_interval) { is_expected.to eq "perfect fourth" }
  its(:to_s) { is_expected.to eq "ascending perfect fourth" }

  it { is_expected.to be_moving }
  it { is_expected.to be_ascending }
  it { is_expected.not_to be_descending }
end