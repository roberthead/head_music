# frozen_string_literal: true

require 'spec_helper'

describe Octave do
  describe '.get' do
    it 'returns an instance when given an octave number' do
      expect(Octave.get(4)).to eq 4
      expect(Octave.get(-1)).to eq -1
      expect(Octave.get(10)).to eq 10
      expect(Octave.get('5')).to eq 5
    end

    it 'falls back to 4' do
      expect(Octave.get('foo')).to eq 4
      expect(Octave.get(1.5)).to eq 4
      expect(Octave.get(15)).to eq 4
    end

    context 'when given an instance' do
      let(:instance) { described_class.get(4) }

      it 'returns that instance' do
        expect(described_class.get(instance)).to be instance
      end
    end
  end

  describe '.new' do
    it 'is private' do
      expect { Octave.new(5) }.to raise_error NoMethodError
    end
  end

  describe 'comparison' do
    specify { expect(Octave.get(2)).to be < Octave.get(3) }
    specify { expect(Octave.get(5)).to be > Octave.get(-1) }
    specify { expect(Octave.get(7)).to be == Octave.get(7) }
  end
end
