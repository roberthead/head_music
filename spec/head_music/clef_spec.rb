require 'spec_helper'

describe Clef do
  subject(:clef) { Clef.get(name) }

  context 'treble clef' do
    let(:name) { :treble }

    its(:clef_type) { is_expected.to eq "G-clef" }

    specify { expect(clef.space_pitch(-1)).to eq 'B3' }
    specify { expect(clef.line_pitch(0)).to eq 'C4' }
    specify { expect(clef.space_pitch(0)).to eq 'D4' }

    specify { expect(clef.line_pitch(1)).to eq 'E4' }
    specify { expect(clef.space_pitch(1)).to eq 'F4' }
    specify { expect(clef.line_pitch(2)).to eq 'G4' }
    specify { expect(clef.space_pitch(2)).to eq 'A4' }
    specify { expect(clef.line_pitch(3)).to eq 'B4' }
    specify { expect(clef.space_pitch(3)).to eq 'C5' }
    specify { expect(clef.line_pitch(4)).to eq 'D5' }
    specify { expect(clef.space_pitch(4)).to eq 'E5' }
    specify { expect(clef.line_pitch(5)).to eq 'F5' }

    specify { expect(clef.space_pitch(5)).to eq 'G5' }
    specify { expect(clef.line_pitch(7)).to eq 'C6' }
  end

  context 'alto clef' do
    let(:name) { :alto }

    its(:clef_type) { is_expected.to eq "C-clef" }

    specify { expect(clef.space_pitch(-1)).to eq 'C3' }
    specify { expect(clef.line_pitch(0)).to eq 'D3' }
    specify { expect(clef.space_pitch(0)).to eq 'E3' }

    specify { expect(clef.line_pitch(1)).to eq 'F3' }
    specify { expect(clef.space_pitch(1)).to eq 'G3' }
    specify { expect(clef.line_pitch(2)).to eq 'A3' }
    specify { expect(clef.space_pitch(2)).to eq 'B3' }
    specify { expect(clef.line_pitch(3)).to eq 'C4' }
    specify { expect(clef.space_pitch(3)).to eq 'D4' }
    specify { expect(clef.line_pitch(4)).to eq 'E4' }
    specify { expect(clef.space_pitch(4)).to eq 'F4' }
    specify { expect(clef.line_pitch(5)).to eq 'G4' }

    specify { expect(clef.space_pitch(5)).to eq 'A4' }
    specify { expect(clef.line_pitch(7)).to eq 'D5' }
  end

  context 'bass clef' do
    let(:name) { :bass }

    its(:clef_type) { is_expected.to eq "F-clef" }

    specify { expect(clef.space_pitch(-1)).to eq 'D2' }
    specify { expect(clef.line_pitch(0)).to eq 'E2' }
    specify { expect(clef.space_pitch(0)).to eq 'F2' }

    specify { expect(clef.line_pitch(1)).to eq 'G2' }
    specify { expect(clef.space_pitch(1)).to eq 'A2' }
    specify { expect(clef.line_pitch(2)).to eq 'B2' }
    specify { expect(clef.space_pitch(2)).to eq 'C3' }
    specify { expect(clef.line_pitch(3)).to eq 'D3' }
    specify { expect(clef.space_pitch(3)).to eq 'E3' }
    specify { expect(clef.line_pitch(4)).to eq 'F3' }
    specify { expect(clef.space_pitch(4)).to eq 'G3' }
    specify { expect(clef.line_pitch(5)).to eq 'A3' }

    specify { expect(clef.space_pitch(5)).to eq 'B3' }
    specify { expect(clef.line_pitch(6)).to eq 'C4' }
    specify { expect(clef.space_pitch(6)).to eq 'D4' }
    specify { expect(clef.line_pitch(7)).to eq 'E4' }
  end
end
