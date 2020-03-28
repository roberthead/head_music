# frozen_string_literal: true

require 'spec_helper'

describe HeadMusic::Circle do
  subject(:circle) { described_class.of_fifths }

  describe '#pitch_classes' do
    it 'lists all the pitch classes starting at C' do
      expect(circle.pitch_class_set).to eq HeadMusic::PitchClassSet.new([0, 7, 2, 9, 4, 11, 6, 1, 8, 3, 10, 5])
    end
  end

  describe '#index' do
    specify { expect(circle.index('Eb')).to eq 9 }
    specify { expect(circle.index('Db')).to eq 7 }
    specify { expect(circle.index('C#')).to eq 7 }
    specify { expect(circle.index('A')).to eq 3 }
  end

  describe '#spellings_up' do
    xcontext 'with enharmonic equivalence' do
      subject(:circle) { described_class.get }

      it 'uses sharp spellings' do
        expect(circle.spellings_up.map(&:to_s)).to eq(%w[C G D A E B F♯ C♯ A♭ E♭ B♭ F])
      end
    end

    context 'without enharmonic equivalence' do
      it 'uses sharp spellings' do
        expect(circle.spellings_up.map(&:to_s)).to eq(%w[C G D A E B F♯ C♯ G♯ D♯ A♯ E♯])
      end
    end
  end

  describe '#spellings_down' do
    xcontext 'with enharmonic equivalence' do
      it 'uses flat spellings' do
        expect(circle.spellings_down.map(&:to_s)).to eq(%w[C F B♭ E♭ A♭ D♭ G♭ B E A D G])
      end
    end

    context 'without enharmonic equivalence' do
      it 'uses flat spellings' do
        expect(circle.spellings_down.map(&:to_s)).to eq(%w[C F B♭ E♭ A♭ D♭ G♭ C♭ F♭ B𝄫 E𝄫 A𝄫])
      end
    end
  end
end
