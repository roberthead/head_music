# frozen_string_literal: true

require "spec_helper"

describe HeadMusic::Note do
  subject(:note) { described_class.new("F#5", :quarter) }

  its(:pitch) { is_expected.to eq "F#5" }
  its(:rhythmic_value) { is_expected.to be_a(HeadMusic::RhythmicValue) }
  its(:voice) { is_expected.to be_a(HeadMusic::Voice) }
  its(:position) { is_expected.to be_a(HeadMusic::Position) }
end
