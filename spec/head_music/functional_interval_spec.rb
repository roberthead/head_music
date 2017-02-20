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

  describe 'naming' do
    specify { expect(FunctionalInterval.new('B2', 'B4').number_name).to eq 'fifteenth' }
    specify { expect(FunctionalInterval.new('B2', 'C#5').number_name).to eq 'sixteenth' }
    specify { expect(FunctionalInterval.new('B2', 'D#5').number_name).to eq 'seventeenth' }
    specify { expect(FunctionalInterval.new('B2', 'E5').number_name).to eq '18th' }

    specify { expect(FunctionalInterval.new('B4', 'B4').name).to eq 'perfect unison' }
    specify { expect(FunctionalInterval.new('B2', 'B4').name).to eq 'perfect fifteenth' }
    specify { expect(FunctionalInterval.new('B2', 'E5').name).to eq 'two octaves and a perfect fourth' }
    specify { expect(FunctionalInterval.new('B2', 'B5').name).to eq 'three octaves' }
    specify { expect(FunctionalInterval.new('C3', 'C#6').name).to eq 'three octaves and an augmented unison' }
  end
end
