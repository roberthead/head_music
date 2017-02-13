require 'spec_helper'

RSpec.describe HeadMusic::Circle do
  subject(:circle) { HeadMusic::Circle.of_fifths }

  describe '.pitch_classes' do
    it 'lists all the pitch classes starting and ending at C' do
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
end
