require 'spec_helper'

describe RhythmicValue do
  subject(:rhythmic_value) { RhythmicValue.get(name) }

  context 'for :whole' do
    let(:name) { :whole }

    its(:relative_value) { is_expected.to eq 1 }
    its(:note_head) { is_expected.to eq :open }
    it { is_expected.not_to have_stem }
    its(:flags) { are_expected.to eq 0 }
    its(:british_name) { is_expected.to eq 'semibreve' }
  end

  context 'for :half' do
    let(:name) { :half }

    its(:relative_value) { is_expected.to eq 1.0/2 }
    its(:note_head) { is_expected.to eq :open }
    it { is_expected.to have_stem }
    its(:flags) { are_expected.to eq 0 }
    its(:british_name) { is_expected.to eq 'minim' }
  end

  context 'for :quarter' do
    let(:name) { :quarter }

    its(:relative_value) { is_expected.to eq 1.0/4 }
    its(:note_head) { is_expected.to eq :closed }
    it { is_expected.to have_stem }
    its(:flags) { are_expected.to eq 0 }
    its(:british_name) { is_expected.to eq 'crotchet' }
  end

  context 'for :eighth' do
    let(:name) { :eighth }

    its(:relative_value) { is_expected.to eq 1.0/8 }
    its(:note_head) { is_expected.to eq :closed }
    it { is_expected.to have_stem }
    its(:flags) { are_expected.to eq 1 }
    its(:british_name) { is_expected.to eq 'quaver' }
  end

  context 'for :sixteenth' do
    let(:name) { :sixteenth }

    its(:relative_value) { is_expected.to eq 1.0/16 }
    its(:note_head) { is_expected.to eq :closed }
    it { is_expected.to have_stem }
    its(:flags) { are_expected.to eq 2 }
    its(:british_name) { is_expected.to eq 'semiquaver' }
  end

  context 'for thirty-second' do
    let(:name) { 'thirty-second' }

    its(:relative_value) { is_expected.to eq 1.0/32 }
    its(:note_head) { is_expected.to eq :closed }
    it { is_expected.to have_stem }
    its(:flags) { are_expected.to eq 3 }
    its(:british_name) { is_expected.to eq 'demisemiquaver' }
  end

  context 'for "double whole"' do
    let(:name) { 'double whole' }

    its(:relative_value) { is_expected.to eq 2 }
    its(:note_head) { is_expected.to eq :breve }
    it { is_expected.not_to have_stem }
    its(:flags) { are_expected.to eq 0 }
    its(:british_name) { is_expected.to eq 'breve' }
  end

  describe '.new' do
    it 'is private' do
      expect { Octave.new(5) }.to raise_error NoMethodError
    end
  end
end
