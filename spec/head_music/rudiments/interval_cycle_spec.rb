# frozen_string_literal: true

require 'spec_helper'

describe HeadMusic::IntervalCycle do
  subject(:diminished_seventh_sonority) { described_class.get(3) }

  describe '.get' do
    it 'accepts a named cycle' do
      expect(described_class.get('C1')).to eq described_class.get(1)
      expect(described_class.get('c2')).to eq described_class.get(2)
      expect(described_class.get('C3')).to eq described_class.get(3)
      expect(described_class.get(:c4)).to eq described_class.get(4)
      expect(described_class.get(:C6)).to eq described_class.get(6)
    end
  end

  context 'for C3' do
    describe '#pitch_classes' do
      it 'lists all the pitch classes starting at C' do
        expect(diminished_seventh_sonority.pitch_classes).to eq([
                                             HeadMusic::PitchClass.get(0),
                                             HeadMusic::PitchClass.get(3),
                                             HeadMusic::PitchClass.get(6),
                                             HeadMusic::PitchClass.get(9),
                                           ])
      end
    end

    describe '#index' do
      specify { expect(diminished_seventh_sonority.index('Eb')).to eq 1 }
      specify { expect(diminished_seventh_sonority.index('A')).to eq 3 }
      specify { expect(diminished_seventh_sonority.index('Db')).to eq nil }
    end
  end
end
