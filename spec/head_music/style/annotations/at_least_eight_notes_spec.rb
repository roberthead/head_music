require 'spec_helper'

describe HeadMusic::Style::Annotations::AtLeastEightNotes do
  let(:voice) { Voice.new }
  subject { described_class.new(voice) }

  context 'with no notes' do
    its(:fitness) { is_expected.to be < 0.1 }
    its(:marks_count) { is_expected.to eq 1}
    its(:first_mark_code) { is_expected.to eq '1:1:000 to 2:1:000' }
  end

  context 'with one note and some rests' do
    before do
      voice.place("3:1", :quarter, 'D')
      voice.place("3:2", :quarter)
      voice.place("3:3", :half)
      voice.place("4:1", :quarter)
      voice.place("4:2", :quarter)
      voice.place("4:3", :quarter)
      voice.place("4:4", :quarter)
      voice.place("5.1", :whole)
    end

    its(:fitness) { is_expected.to be < 0.25 }
    its(:marks_count) { is_expected.to eq 1 }
    its(:first_mark_code) { is_expected.to eq "3:1:000 to 6:1:000" }
  end

  context 'with one too few notes' do
    before do
      voice.place("1:1", :quarter, 'D')
      voice.place("1:2", :quarter, 'E')
      voice.place("1:3", :half, 'F#')
      voice.place("2:1", :quarter, 'D')
      voice.place("2:2", :quarter, 'E')
      voice.place("2:3", :half, 'F#')
      voice.place("3:1", :whole, 'D')
    end

    its(:fitness) { is_expected.to be > 0 }
    its(:fitness) { is_expected.to be < 1 }
  end

  context 'with just enough notes' do
    before do
      voice.place("3:1", :quarter, 'D')
      voice.place("3:2", :quarter, 'E')
      voice.place("3:3", :half, 'F#')
      voice.place("4:1", :quarter, 'G')
      voice.place("4:2", :quarter, 'A')
      voice.place("4:3", :half, 'G')
      voice.place("5.1", :whole, 'E')
      voice.place("6.1", :whole, 'E')
    end

    it { is_expected.to be_adherent }
  end

  context 'with plenty of notes' do
    before do
      voice.place("3:1", :quarter, 'D')
      voice.place("3:2", :quarter, 'E')
      voice.place("3:3", :half, 'F#')
      voice.place("4:1", :quarter, 'G')
      voice.place("4:2", :quarter, 'A')
      voice.place("4:3", :half, 'G')
      voice.place("5.1", :whole, 'F#')
      voice.place("6:1", :quarter, 'D')
      voice.place("6:2", :quarter, 'E')
      voice.place("6:3", :half, 'F#')
      voice.place("7:1", :quarter, 'G')
      voice.place("7:2", :quarter, 'A')
      voice.place("7:3", :half, 'G')
      voice.place("8.1", :whole, 'F#')
    end

    it { is_expected.to be_adherent }
  end
end
