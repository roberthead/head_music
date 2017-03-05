require 'spec_helper'

describe Placement do
  let(:composition) { Composition.new(name: 'Dances with Wolverine') }
  let(:voice) { composition.voices.first }
  let(:position) { '2:2:240' }
  let(:pitch) { Pitch.get('F#4') }
  let(:rhythmic_value) { RhythmicValue.new(:eighth) }

  subject(:placement) { Placement.new(voice, position, rhythmic_value, pitch) }

  its(:composition) { is_expected.to eq composition }
  its(:voice) { is_expected.to eq voice }
  its(:position) { is_expected.to eq Position.new(composition, '2:2:240') }
  its(:pitch) { is_expected.to eq 'F#4' }

  context 'when pitch is omitted' do
    let(:pitch) { nil }

    it { is_expected.to be_rest }
  end

  describe '#next_position' do
    specify { expect(placement.next_position).to eq "2:2:720" }
  end
end
