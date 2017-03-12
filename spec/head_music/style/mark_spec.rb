require 'spec_helper'

describe Style::Mark do
  let(:composition) { Composition.new }
  let(:start_position) { Position.new(composition, "3:2:480") }
  let(:end_position) { Position.new(composition, "4:1") }
  subject(:mark) { Style::Mark.new(start_position, end_position, fitness: 0.9) }

  its(:code) { is_expected.to eq '3:2:480 to 4:1:000' }
  its(:fitness) { is_expected.to eq 0.9 }

  describe '.for' do
    let(:voice) { Voice.new(composition: composition) }
    let(:note) { Placement.new(voice, "5:3", :quarter, 'D5') }
    let(:rest) { Placement.new(voice, "5:4", :quarter) }

    context 'given a single note' do
      subject(:mark) { Style::Mark.for_all(note) }

      its(:placements) { are_expected.to eq [note] }
      its(:code) { is_expected.to eq '5:3:000 to 5:4:000' }
    end

    context 'given multiple placements' do
      subject(:mark) { Style::Mark.for_all([note, rest]) }

      its(:placements) { are_expected.to eq [note, rest] }
      its(:code) { is_expected.to eq '5:3:000 to 6:1:000' }
    end
  end
end
