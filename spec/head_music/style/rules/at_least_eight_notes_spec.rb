require 'spec_helper'

describe HeadMusic::Style::Rules::AtLeastEightNotes do
  let(:voice) { Voice.new }
  let(:rule) { described_class }
  subject(:analysis) { HeadMusic::Style::Analysis.new(rule, voice) }

  context 'when no notes' do
    its(:score) { is_expected.to be < 0.1 }

    it 'is annotated' do
      expect(analysis.annotations.length).to eq 1
    end

    describe 'the annotation' do
      subject(:annotation) { analysis.annotations.first }

      its(:range_string) { is_expected.to eq "1:1:000 to 2:1:000" }

      it 'has a message' do
        expect(annotation.message.length).to be > 8
      end
    end
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

    its(:score) { is_expected.to be < 0.25 }

    specify { expect(analysis.annotations.length).to eq 1 }
    specify { expect(analysis.annotations.first.start_position).to eq "3:1" }
    specify { expect(analysis.annotations.first.end_position).to eq "6:1" }
    specify { expect(analysis.annotations.first.range_string).to eq '3:1:000 to 6:1:000' }
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

    its(:score) { is_expected.to be > 0 }
    its(:score) { is_expected.to be < 1 }
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

    its(:score) { is_expected.to eq 1 }

    its(:annotations) { are_expected.to eq [] }
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

    its(:score) { is_expected.to eq 1 }

    its(:annotations) { are_expected.to eq [] }
  end
end
