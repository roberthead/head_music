require 'spec_helper'

describe Style::Annotation do
  let(:composition) { Composition.new }
  let(:voice) { Voice.new(composition: composition) }
  let(:fitness) { 0.5 }
  let(:message) { "Put the beautiful stuff here." }
  let(:start_position) { Position.new(composition, 2, 1, 0) }
  let(:end_position) { Position.new(composition, 5, 1, 0) }
  let(:mark) { Style::Mark.new(start_position, end_position) }
  subject(:annotation) { described_class.new(subject: voice, fitness: fitness, message: message, marks: [mark]) }

  its(:subject) { is_expected.to eq voice }
  its(:voice) { is_expected.to eq voice }
  its(:composition) { is_expected.to eq composition }
  its(:fitness) { is_expected.to eq 0.5 }
  its(:marks) { are_expected.to eq [mark] }
end
