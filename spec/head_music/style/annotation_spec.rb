require 'spec_helper'

describe HeadMusic::Style::Annotation do
  let(:voice) { Voice.new }
  let(:start_position) { Position.new(voice.composition, 2, 1, 0) }
  let(:end_position) { Position.new(voice.composition, 5, 1, 0) }
  let(:message) { "Put the beautiful stuff here." }
  subject(:annotation) { described_class.new(voice, start_position, end_position, message) }

  its(:description) { is_expected.to eq "2:1:000 to 5:1:000 – Put the beautiful stuff here." }
end
