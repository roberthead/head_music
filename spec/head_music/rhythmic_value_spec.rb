require 'spec_helper'

describe RhythmicValue do
  let(:unit) { RhythmicUnit.get(:quarter) }

  context 'for a dotted quarter' do
    subject(:value) { RhythmicValue.new(unit, dots: 1) }

    its(:name) { is_expected.to eq 'dotted quarter' }
    its(:ticks) { are_expected.to eq 1440 }
  end
end
