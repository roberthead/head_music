require 'spec_helper'

RSpec.describe HeadMusic::Accidental do
  subject(:accidental) {  }

  describe '.semitones' do
    specify { expect(HeadMusic::Accidental.get('#').semitones).to eq 1 }
    specify { expect(HeadMusic::Accidental.get('##').semitones).to eq 2 }
    specify { expect(HeadMusic::Accidental.get('b').semitones).to eq -1 }
    specify { expect(HeadMusic::Accidental.get('bb').semitones).to eq -2 }
    specify { expect(HeadMusic::Accidental.get('foo').semitones).to eq 0 }
    specify { expect(HeadMusic::Accidental.get(nil).semitones).to eq 0 }
    specify { expect(HeadMusic::Accidental.get('').semitones).to eq 0 }
  end

  describe 'equality' do
    specify { expect(HeadMusic::Accidental.get('#')).to eq '#' }
    specify { expect(HeadMusic::Accidental.get('bb')).to eq 'bb' }
  end
end
