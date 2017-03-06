require 'spec_helper'

describe HeadMusic::Style::Rules::NotesSameLength do
  let(:composition) { Composition.new(name: "CF in C") }
  let(:voice) { Voice.new(composition: composition) }
  let(:rule) { described_class }
  subject(:analysis) { HeadMusic::Style::Analysis.new(rule, voice) }

  context 'with no notes' do
    its(:fitness) { is_expected.to eq 1 }
  end

  context 'with one note' do
    before do
      voice.place("1:1", :whole, 'C')
    end

    its(:fitness) { is_expected.to eq 1 }
  end

  context 'with eight whole notes' do
    before do
      %w[C D E F G F A G F D E C].each_with_index do |pitch, bar|
        voice.place("#{bar + 1}:1", :whole, pitch)
      end
    end

    its(:fitness) { is_expected.to eq 1 }
  end

  context 'when ending on a longer note' do
    before do
      %w[C D E F G F A G F D].each_with_index do |pitch, bar|
        voice.place("#{bar + 1}:1", :whole, pitch)
      end
      voice.place(voice.notes.last.next_position, :breve, 'C')
    end

    its(:fitness) { is_expected.to eq 1 }
  end

  context 'when notes are not of equal rhythmic value' do
    before do
      voice.place("1:1", :whole, 'D4')
      voice.place("2:1", :half, 'E4')
      voice.place("2:3", :half, 'F4')
      voice.place("3:1", :whole, 'E4')
      voice.place("2:1", :half, 'E4')
      voice.place("2:3", :half, 'F4')
      voice.place("3:1", :whole, 'E4')
      voice.place("4:1", :whole, 'D4')
    end

    its(:fitness) { is_expected.to be < 1 }

    it 'is annotated' do
      expect(analysis.annotations.length).to eq 1
    end

    describe 'annotation' do
      subject(:annotation) { analysis.annotations.first }

      its(:range_string) { is_expected.to eq "1:1:000 to 5:1:000" }

      it 'has a message' do
        expect(annotation.message.length).to be > 8
      end
    end
  end
end
