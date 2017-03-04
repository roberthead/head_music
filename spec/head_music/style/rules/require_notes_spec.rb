require 'spec_helper'

describe HeadMusic::Style::Rules::RequireNotes do
  let(:voice) { Voice.new }
  let(:rule) { HeadMusic::Style::Rules::RequireNotes }
  subject(:analysis) { HeadMusic::Style::Analysis.new(rule, voice) }

  context 'when no notes' do
    its(:score) { is_expected.to eq 0 }
  end

  context 'with one note and six rests' do
    before do
      voice.place("3:1", :quarter, 'D')
      voice.place("3:2", :quarter)
      voice.place("3:3", :half)
      voice.place("4:1", :quarter)
      voice.place("4:2", :quarter)
      voice.place("4:3", :half)
      voice.place("5.1", :whole)
    end

    its(:score) { is_expected.to be < 0.25 }
  end

  context 'with a few notes' do
    before do
      voice.place("3:1", :quarter, 'D')
      voice.place("3:2", :quarter, 'E')
      voice.place("3:3", :half, 'F#')
    end

    its(:score) { is_expected.to be > 0 }
    its(:score) { is_expected.to be < 1 }
  end

  context 'with seven notes' do
    before do
      voice.place("3:1", :quarter, 'D')
      voice.place("3:2", :quarter, 'E')
      voice.place("3:3", :half, 'F#')
      voice.place("4:1", :quarter, 'G')
      voice.place("4:2", :quarter, 'A')
      voice.place("4:3", :half, 'G')
      voice.place("5.1", :whole, 'F#')
    end

    its(:score) { is_expected.to eq 1 }
  end

  context 'with lots of notes' do
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
  end
end
