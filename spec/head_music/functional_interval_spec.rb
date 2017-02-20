require 'spec_helper'

describe FunctionalInterval do
  context 'given a simple interval' do
    subject { FunctionalInterval.new('A4', 'E5') }

    its(:name) { is_expected.to eq 'perfect fifth' }
    its(:number) { is_expected.to eq 5 }
    its(:number_name) { is_expected.to eq 'fifth' }
    its(:quality) { is_expected.to eq :perfect }
    its(:shorthand) { is_expected.to eq 'P5' }
    it { is_expected.to be_simple }
    it { is_expected.not_to be_compound }
  end

  context 'given a compound interval' do
    subject { FunctionalInterval.new('E3', 'C5') }

    its(:name) { is_expected.to eq 'minor thirteenth' }
    its(:number) { is_expected.to eq 13 }
    its(:number_name) { is_expected.to eq 'thirteenth' }
    its(:quality) { is_expected.to eq 'minor' }
    its(:shorthand) { is_expected.to eq 'm13' }
    it { is_expected.not_to be_simple }
    it { is_expected.to be_compound }
  end
end
