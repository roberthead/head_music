# frozen_string_literal: true

require 'spec_helper'

describe Meter do
  describe '.get' do
    context 'when given an instance' do
      let(:instance) { described_class.get('5/4') }

      it 'returns that instance' do
        expect(described_class.get(instance)).to be instance
      end
    end

    context 'given 3/4' do
      subject(:meter) { Meter.get('3/4') }

      it { is_expected.to be_simple }
      it { is_expected.not_to be_compound }

      it { is_expected.not_to be_duple }
      it { is_expected.to be_triple }
      it { is_expected.not_to be_quadruple }

      its(:beats_per_bar) { are_expected.to eq 3 }
      its(:counts_per_bar) { are_expected.to eq 3 }
      its(:beat_unit) { is_expected.to eq :quarter }
      its(:strong_counts) { are_expected.to eq [1] }
      its(:ticks_per_count) { are_expected.to eq 960 }
    end

    context 'given 6/8' do
      subject(:meter) { Meter.get('6/8') }

      it { is_expected.not_to be_simple }
      it { is_expected.to be_compound }

      it { is_expected.not_to be_duple }
      it { is_expected.to be_triple }
      it { is_expected.not_to be_quadruple }

      its(:beats_per_bar) { are_expected.to eq 2 }
      its(:counts_per_bar) { are_expected.to eq 6 }
      its(:beat_unit) { is_expected.to eq 'dotted quarter' }
      its(:strong_counts) { are_expected.to eq [1, 4] }
      its(:ticks_per_count) { are_expected.to eq 480 }
    end

    context 'given 9/8' do
      subject(:meter) { Meter.get('9/8') }

      it { is_expected.not_to be_simple }
      it { is_expected.to be_compound }

      it { is_expected.not_to be_duple }
      it { is_expected.to be_triple }
      it { is_expected.not_to be_quadruple }

      its(:beats_per_bar) { are_expected.to eq 3 }
      its(:counts_per_bar) { are_expected.to eq 9 }
      its(:beat_unit) { is_expected.to eq 'dotted quarter' }
      its(:strong_counts) { are_expected.to eq [1, 4, 7] }
      its(:ticks_per_count) { are_expected.to eq 480 }
    end

    context 'given :common_time' do
      subject(:meter) { Meter.get(:common_time) }

      it { is_expected.to be_simple }
      it { is_expected.not_to be_compound }

      it { is_expected.not_to be_duple }
      it { is_expected.not_to be_triple }
      it { is_expected.to be_quadruple }

      its(:beats_per_bar) { are_expected.to eq 4 }
      its(:counts_per_bar) { are_expected.to eq 4 }
      its(:beat_unit) { is_expected.to eq 'quarter' }
      its(:strong_counts) { are_expected.to eq [1, 3] }
      its(:ticks_per_count) { are_expected.to eq 960 }
    end

    context 'given :cut_time' do
      subject(:meter) { Meter.get(:cut_time) }

      it { is_expected.to be_simple }
      it { is_expected.not_to be_compound }

      it { is_expected.to be_duple }
      it { is_expected.not_to be_triple }
      it { is_expected.not_to be_quadruple }

      its(:beats_per_bar) { are_expected.to eq 2 }
      its(:counts_per_bar) { are_expected.to eq 2 }
      its(:beat_unit) { is_expected.to eq :half }
      its(:strong_counts) { are_expected.to eq [1, 2] }
      its(:ticks_per_count) { are_expected.to eq 1920 }
    end
  end

  describe '#beat_strength' do
    context 'for 6/8' do
      subject(:meter) { Meter.get('6/8') }

      specify { expect(meter.beat_strength(1)).to be > meter.beat_strength(4) }
      specify { expect(meter.beat_strength(4)).to be > meter.beat_strength(3) }
      specify { expect(meter.beat_strength(3)).to eq meter.beat_strength(5) }
      specify { expect(meter.beat_strength(3)).to eq meter.beat_strength(2) }
      specify { expect(meter.beat_strength(3)).to be > meter.beat_strength(1, tick: 240) }
      specify { expect(meter.beat_strength(1, tick: 240)).to be > meter.beat_strength(1, tick: 270) }
    end
  end

  describe 'named meter class methods' do
    specify { expect(Meter.common_time).to eq Meter.get('4/4') }
    specify { expect(Meter.cut_time).to eq Meter.get('2/2') }
  end
end
