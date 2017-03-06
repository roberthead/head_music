require 'spec_helper'

describe HeadMusic::Style::Rules::NotesSameLength do
  let(:composition) { Composition.new(name: "CF in C") }
  let(:voice) { Voice.new(composition: composition) }
  let(:rule) { described_class }
  subject(:annotation) { rule.analyze(voice) }

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
    its(:message) { is_expected.not_to be_empty }
    its(:marks_count) { is_expected.to eq 4 }
    its(:first_mark_code) { is_expected.to eq "2:1:000 to 2:3:000" }
  end
end
