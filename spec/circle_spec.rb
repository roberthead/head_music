require 'spec_helper'

RSpec.describe HeadMusic::Circle do
  subject(:circle) { HeadMusic::Circle.of_fifths }

  describe '.pitch_classes' do
    it 'lists all the pitch classes starting at C' do
      expect(circle.pitch_classes).to eq([
        HeadMusic::PitchClass.get(0),
        HeadMusic::PitchClass.get(7),
        HeadMusic::PitchClass.get(2),
        HeadMusic::PitchClass.get(9),
        HeadMusic::PitchClass.get(4),
        HeadMusic::PitchClass.get(11),
        HeadMusic::PitchClass.get(6),
        HeadMusic::PitchClass.get(1),
        HeadMusic::PitchClass.get(8),
        HeadMusic::PitchClass.get(3),
        HeadMusic::PitchClass.get(10),
        HeadMusic::PitchClass.get(5),
      ])
    end
  end

  describe '.index' do
    specify { expect(circle.index('Eb')).to eq 9 }
    specify { expect(circle.index('Db')).to eq 7 }
    specify { expect(circle.index('C#')).to eq 7 }
    specify { expect(circle.index('A')).to eq 3 }
  end
end
