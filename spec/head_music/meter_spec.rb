require 'spec_helper'

describe Meter do
  context 'given 3/4' do
    subject(:meter) { Meter.get('3/4') }

    it { is_expected.to be_simple}
    it { is_expected.not_to be_compound }

    it { is_expected.not_to be_duple }
    it { is_expected.to be_triple }
    it { is_expected.not_to be_quadruple }

    its(:beats_per_measure) { are_expected.to eq 3 }
  end

  context 'given 9/8' do
    subject(:meter) { Meter.get('9/8') }

    it { is_expected.not_to be_simple}
    it { is_expected.to be_compound }

    it { is_expected.not_to be_duple }
    it { is_expected.to be_triple }
    it { is_expected.not_to be_quadruple }

    its(:beats_per_measure) { are_expected.to eq 3 }
  end

  context 'given :common_time' do
    subject(:meter) { Meter.get(:common_time) }

    it { is_expected.to be_simple}
    it { is_expected.not_to be_compound }

    it { is_expected.not_to be_duple }
    it { is_expected.not_to be_triple }
    it { is_expected.to be_quadruple }

    its(:beats_per_measure) { are_expected.to eq 4 }
  end

  context 'given :cut_time' do
    subject(:meter) { Meter.get(:cut_time) }

    it { is_expected.to be_simple}
    it { is_expected.not_to be_compound }

    it { is_expected.to be_duple }
    it { is_expected.not_to be_triple }
    it { is_expected.not_to be_quadruple }

    its(:beats_per_measure) { are_expected.to eq 2 }
  end
end
