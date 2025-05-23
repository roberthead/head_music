require "spec_helper"

describe HeadMusic::Content::Note do
  subject(:note) { described_class.new("F#5", :quarter) }

  its(:pitch) { is_expected.to eq "F#5" }
  its(:rhythmic_value) { is_expected.to be_a(HeadMusic::Content::RhythmicValue) }
  its(:voice) { is_expected.to be_a(HeadMusic::Content::Voice) }
  its(:position) { is_expected.to be_a(HeadMusic::Content::Position) }
  its(:to_s) { is_expected.to eq "F♯5 at 1:1:000" }
  it { is_expected.to be_note }
  it { is_expected.not_to be_rest }
end
