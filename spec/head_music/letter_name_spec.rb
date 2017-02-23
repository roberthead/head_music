require 'spec_helper'

describe LetterName do
  describe '.get' do
    context "fetched with 'A'" do
      subject(:letter) { LetterName.get('A') }

      specify { expect(letter.pitch_class).to eq 9 }
      specify { expect(letter).to eq 'A' }
    end

    context "fetched with 'd#7'" do
      subject(:letter) { LetterName.get('d#7') }

      specify { expect(letter.pitch_class).to eq 2 }
      specify { expect(letter).to eq 'D' }
    end

    context "fetched with 'X'" do
      subject(:letter) { LetterName.get('X') }

      specify { expect(letter).to be_nil }
    end

    context 'when given an instance' do
      let(:instance) { described_class.get('C#4') }

      it 'returns that instance' do
        expect(described_class.get(instance)).to be instance
      end
    end
  end

  describe '.from_pitch_class' do
    specify { expect(LetterName.from_pitch_class(0)).to eq 'C' }
    specify { expect(LetterName.from_pitch_class(1)).to eq 'C' }
    specify { expect(LetterName.from_pitch_class(2)).to eq 'D' }
    specify { expect(LetterName.from_pitch_class(3)).to eq 'E' }
    specify { expect(LetterName.from_pitch_class(4)).to eq 'E' }
    specify { expect(LetterName.from_pitch_class(5)).to eq 'F' }
    specify { expect(LetterName.from_pitch_class(6)).to eq 'F' }
    specify { expect(LetterName.from_pitch_class(7)).to eq 'G' }
    specify { expect(LetterName.from_pitch_class(8)).to eq 'A' }
    specify { expect(LetterName.from_pitch_class(9)).to eq 'A' }
    specify { expect(LetterName.from_pitch_class(10)).to eq 'B' }
    specify { expect(LetterName.from_pitch_class(11)).to eq 'B' }
    specify { expect(LetterName.from_pitch_class(12)).to eq 'C' }
  end

  describe '#cycle' do
    subject(:letter) { LetterName.get('D') }

    its(:cycle) { is_expected.to eq %w[D E F G A B C] }
  end

  describe 'position' do
    specify { expect(LetterName.get('C').position).to eq 3 }
  end

  describe 'steps' do
    specify { expect(LetterName.get('C').steps(5)).to eq 'A' }
  end

  describe 'steps_to' do
    specify { expect(LetterName.get('C').steps_to('G')).to eq 4 }
    specify { expect(LetterName.get('A').steps_to('E')).to eq 4 }
    specify { expect(LetterName.get('F#').steps_to('F#')).to eq 0 }
    specify { expect(LetterName.get('F#').steps_to('E')).to eq 6 }
    specify { expect(LetterName.get('F#').steps_to('E', :descending)).to eq 1 }

    it 'inverts' do
      LetterName::NAMES.each do |from_letter_name|
        LetterName::NAMES.each do |to_letter_name|
          from_letter = LetterName.get(from_letter_name)
          to_letter = LetterName.get(to_letter_name)
          steps_up = from_letter.steps_to(to_letter, :ascending)
          steps_down = from_letter.steps_to(to_letter, :descending)
          if from_letter_name == to_letter_name
            expect(steps_up + steps_down).to eq 0
          else
            expect(steps_up + steps_down).to eq LetterName::NAMES.length
          end
        end
      end
    end
  end
end
