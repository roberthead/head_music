# frozen_string_literal: true

require 'spec_helper'

describe HeadMusic::Register do
  describe '.get' do
    it 'returns an instance when given an octave number' do
      expect(described_class.get(4)).to eq 4
      expect(described_class.get(-1)).to eq(-1)
      expect(described_class.get(10)).to eq 10
      expect(described_class.get('5')).to eq 5
    end

    it 'falls back to 4' do
      expect(described_class.get('foo')).to eq 4
      expect(described_class.get('C')).to eq 4
      expect(described_class.get('D')).to eq 4
      expect(described_class.get('')).to eq 4
      expect(described_class.get(1.5)).to eq 4
      expect(described_class.get(15)).to eq 4
    end

    context 'when given an instance' do
      let(:instance) { described_class.get(4) }

      it 'returns that instance' do
        expect(described_class.get(instance)).to be instance
      end
    end
  end

  describe '.from_name' do
    specify { expect(described_class.from_name('F#5')).to eq 5 }
  end

  describe '.new' do
    it 'is private' do
      expect { described_class.new(5) }.to raise_error NoMethodError
    end
  end

  describe 'comparison' do
    specify { expect(described_class.get(2)).to be < described_class.get(3) }
    specify { expect(described_class.get(5)).to be > described_class.get(-1) }
    specify { expect(described_class.get(7)).to be == described_class.get(7) }
  end

  describe 'addition' do
    specify { expect(described_class.get(4) + 1).to be == described_class.get(5) }
  end

  describe 'subtraction' do
    specify { expect(described_class.get(5) - 3).to be == described_class.get(2) }
    specify { expect(described_class.get(4) - 5).to be == described_class.get(-1) }
  end

  describe 'helmholtz notation' do
    specify do
      expect(described_class.get(0).helmholtz_case).to be :upper
      expect(described_class.get(0).helmholtz_marks).to eq ',,'
      expect(described_class.get(1).helmholtz_case).to be :upper
      expect(described_class.get(1).helmholtz_marks).to eq ','
      expect(described_class.get(2).helmholtz_case).to be :upper
      expect(described_class.get(2).helmholtz_marks).to eq ''
      expect(described_class.get(3).helmholtz_case).to be :lower
      expect(described_class.get(3).helmholtz_marks).to eq ''
      expect(described_class.get(4).helmholtz_case).to be :lower
      expect(described_class.get(4).helmholtz_marks).to eq "'"
      expect(described_class.get(5).helmholtz_case).to be :lower
      expect(described_class.get(5).helmholtz_marks).to eq "''"
      expect(described_class.get(6).helmholtz_case).to be :lower
      expect(described_class.get(6).helmholtz_marks).to eq "'''"
      expect(described_class.get(7).helmholtz_case).to be :lower
      expect(described_class.get(7).helmholtz_marks).to eq "''''"
      expect(described_class.get(8).helmholtz_case).to be :lower
      expect(described_class.get(8).helmholtz_marks).to eq "'''''"
    end
  end
end
