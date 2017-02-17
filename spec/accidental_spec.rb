require 'spec_helper'

RSpec.describe HeadMusic::Accidental do
  describe '.get' do
    specify { expect(HeadMusic::Accidental.get('#').semitones).to eq 1 }
    specify { expect(HeadMusic::Accidental.get(1)).to eq '#' }
    specify { expect(HeadMusic::Accidental.get('foo')).to be_nil }
    specify { expect(HeadMusic::Accidental.get(nil)).to be_nil }
    specify { expect(HeadMusic::Accidental.get('')).to be_nil }
  end

  describe '#semitones' do
    specify { expect(HeadMusic::Accidental.get('#').semitones).to eq 1 }
    specify { expect(HeadMusic::Accidental.get('##').semitones).to eq 2 }
    specify { expect(HeadMusic::Accidental.get('b').semitones).to eq -1 }
    specify { expect(HeadMusic::Accidental.get('bb').semitones).to eq -2 }
  end

  describe 'equality' do
    specify { expect(HeadMusic::Accidental.get('#')).to eq '#' }
    specify { expect(HeadMusic::Accidental.get('bb')).to eq 'bb' }
  end
end
