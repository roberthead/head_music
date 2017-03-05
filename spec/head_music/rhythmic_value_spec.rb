require 'spec_helper'

describe RhythmicValue do
  subject(:value) { RhythmicValue.new(unit, dots: dots) }
  let(:dots) { nil }

  context 'for a dotted half' do
    let(:unit) { RhythmicUnit.get(:half) }
    let(:dots) { 1 }

    its(:name) { is_expected.to eq 'dotted half' }
    its(:ticks) { are_expected.to eq 960 * 3 }
    its(:relative_value) { is_expected.to eq 3.0/4 }
    its(:total_value) { is_expected.to eq 3.0/4 }
  end

  context 'for a dotted quarter' do
    let(:unit) { RhythmicUnit.get(:quarter) }
    let(:dots) { 1 }

    its(:name) { is_expected.to eq 'dotted quarter' }
    its(:ticks) { are_expected.to eq 1440 }
    its(:relative_value) { is_expected.to eq 1.5/4 }
    its(:total_value) { is_expected.to eq 1.5/4 }
  end

  context 'for a sixteenth' do
    let(:unit) { RhythmicUnit.get(:sixteenth) }

    its(:name) { is_expected.to eq 'sixteenth' }
    its(:ticks) { are_expected.to eq 240 }
    its(:relative_value) { is_expected.to eq 1.0/16 }
    its(:total_value) { is_expected.to eq 1.0/16 }
  end

  context 'for a triple-dotted half' do
    let(:unit) { RhythmicUnit.get(:half) }
    let(:dots) { 3 }

    its(:name) { is_expected.to eq 'triple-dotted half' }
    its(:ticks) { are_expected.to eq 3600 }
    its(:relative_value) { is_expected.to eq (0.5 + 0.25 + 0.125 + 0.0625) }
    its(:total_value) { is_expected.to eq (0.5 + 0.5/2 + 0.5/4 + 0.5/8) }
  end

  context 'for an eighth tied to a dotted quarter' do
    subject(:value) { RhythmicValue.new(:eighth, tied_value: second_value) }
    let(:second_value) { RhythmicValue.new(:quarter, dots: 1) }

    its(:name) { is_expected.to eq 'eighth tied to dotted quarter' }
    its(:ticks) { are_expected.to eq 1920 }
    its(:relative_value) { is_expected.to eq 0.125 }
    its(:total_value) { is_expected.to eq 0.5 }
  end

  context 'for a half tied to a quarter tied to an eighth' do
    subject(:value) { RhythmicValue.new(:half, tied_value: second_value) }
    let(:second_value) { RhythmicValue.new(:quarter, tied_value: third_value) }
    let(:third_value) { RhythmicValue.new(:eighth) }

    its(:name) { is_expected.to eq 'half tied to quarter tied to eighth' }
    its(:ticks) { are_expected.to eq 960 * 4 * 7.0 / 8 }
    its(:relative_value) { is_expected.to eq 0.5 }
    its(:total_value) { is_expected.to eq 7.0 / 8 }
  end
end
