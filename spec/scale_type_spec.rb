require 'spec_helper'

describe ScaleType do
  describe 'new' do
    it 'is public' do
      expect { ScaleType.new([12]) }.not_to raise_error
    end
  end

  describe '.melodic_minor' do
    subject(:melodic_minor) { ScaleType.melodic_minor }

    its(:ascending_intervals) { are_expected.to eq [2, 1, 2, 2, 2, 2, 1] }
    its(:descending_intervals) { are_expected.not_to eq subject.ascending_intervals.reverse }
    its(:descending_intervals) { are_expected.to eq [2, 2, 1, 2, 2, 1, 2] }
  end

  [:ionian, :dorian, :phrygian, :lydian, :mixolydian, :aeolian, :locrian].each do |mode|
    describe "#{mode} mode" do
      subject { ScaleType.send(mode) }

      its(:descending_intervals) { are_expected.to eq subject.ascending_intervals.reverse }

      it 'consists entirely of whole and half steps' do
        expect(subject.ascending_intervals.uniq.sort).to eq [1, 2]
      end
    end
  end

  describe '.major' do
    subject(:major) { ScaleType.major }

    its(:ascending_intervals) { are_expected.to eq [2, 2, 1, 2, 2, 2, 1] }
    its(:descending_intervals) { are_expected.to eq subject.ascending_intervals.reverse }
    it { is_expected.to eq ScaleType.ionian }
  end

  describe '.dorian' do
    subject(:dorian) { ScaleType.dorian }

    its(:ascending_intervals) { are_expected.to eq [2, 1, 2, 2, 2, 1, 2] }
    its(:descending_intervals) { are_expected.to eq subject.ascending_intervals.reverse }
  end

  describe 'equality' do
    specify { expect(ScaleType.natural_minor).to eq ScaleType.aeolian }
    specify { expect(ScaleType.natural_minor).not_to eq ScaleType.harmonic_minor }
    specify { expect(ScaleType.natural_minor).not_to eq ScaleType.melodic_minor }
    specify { expect(ScaleType.harmonic_minor).not_to eq ScaleType.melodic_minor }
  end
end
