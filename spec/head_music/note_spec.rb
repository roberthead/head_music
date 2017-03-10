require 'spec_helper'

describe Note do
  subject(:note) { Note.new("F#5", :quarter) }

  its(:pitch) { is_expected.to eq 'F#5' }
  its(:rhythmic_value) { is_expected.to be_a(HeadMusic::RhythmicValue) }
  its(:voice) { is_expected.to be_a(HeadMusic::Voice) }
  its(:position) { is_expected.to be_a(HeadMusic::Position) }
end
