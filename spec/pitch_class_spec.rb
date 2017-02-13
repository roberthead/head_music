require 'spec_helper'

RSpec.describe HeadMusic::PitchClass do
  subject(:pitch_class) { HeadMusic::PitchClass.get(number) }

  context 'when constructed with a number between zero and eleven' do
    let(:number) { rand(12) }

    specify { expect(pitch_class.number).to eq number }
    specify { expect(pitch_class.to_i).to eq number }
  end

  context 'when constructed with a midi note number' do
    let(:number) { 53 } # F3

    specify { expect(pitch_class.number).to eq 5 } # F
    specify { expect(pitch_class).to eq 5 }
  end

  describe 'equality' do
    specify { expect(HeadMusic::PitchClass.get(53)).to eq HeadMusic::PitchClass.get(5) }
  end

  describe 'addition' do
    specify { expect(HeadMusic::PitchClass.get(60) + 3).to eq HeadMusic::PitchClass.get(63) }
    specify { expect(HeadMusic::PitchClass.get(4) + HeadMusic::Interval.get(3)).to eq HeadMusic::PitchClass.get(7) }
  end

  describe 'subtraction' do
    specify { expect(HeadMusic::PitchClass.get(60) - 3).to eq HeadMusic::PitchClass.get(57) }
    specify { expect(HeadMusic::PitchClass.get(4) - HeadMusic::Interval.get(3)).to eq HeadMusic::PitchClass.get(1) }
  end

  describe '#intervals_to' do
    specify { expect(HeadMusic::PitchClass.get(7).intervals_to(5).map(&:to_i)).to eq [-2, 10] }
    specify { expect(HeadMusic::PitchClass.get(1).intervals_to(10).map(&:to_i)).to eq [-3, 9] }
    specify { expect(HeadMusic::PitchClass.get(10).intervals_to(1).map(&:to_i)).to eq [3, -9] }
  end

  describe '#smallest_interval_to' do
    specify { expect(HeadMusic::PitchClass.get(7).smallest_interval_to(5)).to eq -2 }
    specify { expect(HeadMusic::PitchClass.get(1).smallest_interval_to(10)).to eq -3 }
    specify { expect(HeadMusic::PitchClass.get(10).smallest_interval_to(1)).to eq 3 }
    specify { expect(HeadMusic::PitchClass.get(11).smallest_interval_to(0)).to eq 1 }
    specify { expect(HeadMusic::PitchClass.get(0).smallest_interval_to(11)).to eq -1 }
  end
end
