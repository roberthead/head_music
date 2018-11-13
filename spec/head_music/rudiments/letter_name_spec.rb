# frozen_string_literal: true

require 'spec_helper'

describe HeadMusic::LetterName do
  describe '.get' do
    context "fetched with 'A'" do
      subject(:letter_name) { described_class.get('A') }

      specify { expect(letter_name.pitch_class).to eq 9 }
      specify { expect(letter_name).to eq 'A' }
    end

    context "fetched with 'd#7'" do
      subject(:letter_name) { described_class.get('d#7') }

      specify { expect(letter_name.pitch_class).to eq 2 }
      specify { expect(letter_name).to eq 'D' }
    end

    context "fetched with 'X'" do
      subject(:letter_name) { described_class.get('X') }

      specify { expect(letter_name).to be_nil }
    end

    context 'when given an instance' do
      let(:instance) { described_class.get('C#4') }

      it 'returns that instance' do
        expect(described_class.get(instance)).to be instance
      end
    end
  end

  describe '.from_pitch_class' do
    specify { expect(described_class.from_pitch_class(0)).to eq 'C' }
    specify { expect(described_class.from_pitch_class(1)).to eq 'C' }
    specify { expect(described_class.from_pitch_class(2)).to eq 'D' }
    specify { expect(described_class.from_pitch_class(3)).to eq 'D' }
    specify { expect(described_class.from_pitch_class(4)).to eq 'E' }
    specify { expect(described_class.from_pitch_class(5)).to eq 'F' }
    specify { expect(described_class.from_pitch_class(6)).to eq 'F' }
    specify { expect(described_class.from_pitch_class(7)).to eq 'G' }
    specify { expect(described_class.from_pitch_class(8)).to eq 'G' }
    specify { expect(described_class.from_pitch_class(9)).to eq 'A' }
    specify { expect(described_class.from_pitch_class(10)).to eq 'A' }
    specify { expect(described_class.from_pitch_class(11)).to eq 'B' }
    specify { expect(described_class.from_pitch_class(12)).to eq 'C' }
  end

  describe '#series_ascending' do
    subject(:letter_name) { described_class.get('D') }

    its(:series_ascending) { is_expected.to eq %w[D E F G A B C] }
  end

  describe '#series_descending' do
    subject(:letter_name) { described_class.get('D') }

    its(:series_descending) { is_expected.to eq %w[D C B A G F E] }
  end

  describe 'steps_up' do
    specify { expect(described_class.get('C').steps_up(5)).to eq 'A' }
    specify { expect(described_class.get('C').steps_up(8)).to eq 'D' }
  end

  describe 'steps_down' do
    specify { expect(described_class.get('C').steps_down(5)).to eq 'E' }
    specify { expect(described_class.get('C').steps_down(8)).to eq 'B' }
  end

  describe 'steps_to' do
    specify { expect(described_class.get('C').steps_to('G')).to eq 4 }
    specify { expect(described_class.get('A').steps_to('E')).to eq 4 }
    specify { expect(described_class.get('F#').steps_to('F#')).to eq 0 }
    specify { expect(described_class.get('F#').steps_to('E')).to eq 6 }
    specify { expect(described_class.get('F#').steps_to('E', :descending)).to eq 1 }

    it 'inverts' do
      described_class::NAMES.each do |from_letter_name|
        described_class::NAMES.each do |to_letter_name|
          from_letter = described_class.get(from_letter_name)
          to_letter = described_class.get(to_letter_name)
          steps_up = from_letter.steps_to(to_letter, :ascending)
          steps_down = from_letter.steps_to(to_letter, :descending)
          if from_letter_name == to_letter_name
            expect(steps_up + steps_down).to eq 0
          else
            expect(steps_up + steps_down).to eq described_class::NAMES.length
          end
        end
      end
    end
  end
end
