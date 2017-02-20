require 'spec_helper'

describe Circle do
  subject(:circle) { Circle.of_fifths }

  describe '#pitch_classes' do
    it 'lists all the pitch classes starting at C' do
      expect(circle.pitch_classes).to eq([
        PitchClass.get(0),
        PitchClass.get(7),
        PitchClass.get(2),
        PitchClass.get(9),
        PitchClass.get(4),
        PitchClass.get(11),
        PitchClass.get(6),
        PitchClass.get(1),
        PitchClass.get(8),
        PitchClass.get(3),
        PitchClass.get(10),
        PitchClass.get(5),
      ])
    end
  end

  describe '#index' do
    specify { expect(circle.index('Eb')).to eq 9 }
    specify { expect(circle.index('Db')).to eq 7 }
    specify { expect(circle.index('C#')).to eq 7 }
    specify { expect(circle.index('A')).to eq 3 }
  end
end
