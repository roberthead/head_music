require 'spec_helper'

describe HeadMusic::Spelling do
  context "for 'C'" do
    subject(:spelling) { HeadMusic::Spelling.get('C') }

    its(:letter) { is_expected.to eq 'C' }
    its(:accidental) { is_expected.to eq '' }
    its(:pitch_class) { is_expected.to eq 0 }
    it { is_expected.to eq 'C' }
  end

  context "for 'F#'" do
    subject(:spelling) { HeadMusic::Spelling.get('F#') }

    its(:letter) { is_expected.to eq 'F' }
    its(:accidental) { is_expected.to eq '#' }
    its(:pitch_class) { is_expected.to eq 6 }
    it { is_expected.to eq 'F#' }
  end

  context "for 'Bb'" do
    subject(:spelling) { HeadMusic::Spelling.get('Bb') }

    its(:letter) { is_expected.to eq 'B' }
    its(:accidental) { is_expected.to eq 'b' }
    its(:pitch_class) { is_expected.to eq 10 }
    it { is_expected.to eq 'Bb' }
  end

  context "for 'Eb7'" do
    subject(:spelling) { HeadMusic::Spelling.get('Eb7') }

    its(:letter) { is_expected.to eq 'E' }
    its(:accidental) { is_expected.to eq 'b' }
    its(:pitch_class) { is_expected.to eq 3 }
    it { is_expected.to eq 'Eb' }
  end

  context "for 'Cb'" do
    subject(:spelling) { HeadMusic::Spelling.get('Cb') }

    its(:letter) { is_expected.to eq 'C' }
    its(:accidental) { is_expected.to eq 'b' }
    its(:pitch_class) { is_expected.to eq 11 }
    it { is_expected.to eq 'Cb' }
  end

  context "for 'B#'" do
    subject(:spelling) { HeadMusic::Spelling.get('B#') }

    its(:letter) { is_expected.to eq 'B' }
    its(:accidental) { is_expected.to eq '#' }
    its(:pitch_class) { is_expected.to eq 0 }
    it { is_expected.to eq 'B#' }
  end
end
