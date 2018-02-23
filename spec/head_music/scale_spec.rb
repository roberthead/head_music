# frozen_string_literal: true

require 'spec_helper'

describe Scale do
  describe 'default scale' do
    specify { expect(Scale.get('G').spellings).to eq %w[G A B C D E F♯ G] }
  end

  describe 'spelling' do
    describe 'accuracy' do
      specify { expect(Scale.get('D4', :major).spellings).to eq %w[D E F♯ G A B C♯ D] }
      specify { expect(Scale.get('C♯3', :major).spellings).to eq %w[C♯ D♯ E♯ F♯ G♯ A♯ B♯ C♯] }
      specify { expect(Scale.get('F♯3', :natural_minor).spellings).to eq %w[F♯ G♯ A B C♯ D E F♯] }
      specify { expect(Scale.get('F♯3', :harmonic_minor).spellings).to eq %w[F♯ G♯ A B C♯ D E♯ F♯] }
      specify { expect(Scale.get('F♯3', :melodic_minor).spellings).to eq %w[F♯ G♯ A B C♯ D♯ E♯ F♯] }
      specify { expect(Scale.get('D', :harmonic_minor).spellings).to eq %w[D E F G A B♭ C♯ D] }
      specify { expect(Scale.get('B♭', :dorian).spellings).to eq %w[B♭ C D♭ E♭ F G A♭ B♭] }
      specify { expect(Scale.get('B', :locrian).spellings).to eq %w[B C D E F G A B] }
      specify { expect(Scale.get('C', :minor_pentatonic).spellings).to eq %w[C E♭ F G B♭ C] }
      specify { expect(Scale.get('F♯', :major_pentatonic).spellings).to eq %w[F♯ G♯ A♯ C♯ D♯ F♯] }
      specify { expect(Scale.get('G♭', :major_pentatonic).spellings).to eq %w[G♭ A♭ B♭ D♭ E♭ G♭] }
      specify { expect(Scale.get('F', :minor_pentatonic).spellings).to eq %w[F A♭ B♭ C E♭ F] }
      specify { expect(Scale.get('F', :major).spellings).to eq %w[F G A B♭ C D E F] }
      specify { expect(Scale.get('C', :whole_tone).spellings).to eq %w[C D E F♯ G♯ A♯ C] }
      specify { expect(Scale.get('C♯', :whole_tone).spellings).to eq %w[C♯ D♯ F G A B C♯] }
      specify { expect(Scale.get('D♭', :whole_tone).spellings).to eq %w[D♭ E♭ F G A B D♭] }
      specify { expect(Scale.get('C', :chromatic).spellings).to eq %w[C C♯ D D♯ E F F♯ G G♯ A A♯ B C] }
      specify { expect(Scale.get('C♯', :chromatic).spellings).to eq %w[C♯ D D♯ E F F♯ G G♯ A A♯ B C C♯] }
    end

    describe 'options' do
      subject(:scale) { Scale.get('C', :minor_pentatonic) }

      specify do
        expect(scale.spellings(direction: :both, octaves: 2)).to eq %w[C E♭ F G B♭ C E♭ F G B♭ C B♭ G F E♭ C B♭ G F E♭ C]
      end
    end
  end

  describe '#degree' do
    let(:scale) { Scale.get('B♭', :major) }

    specify { expect(scale.degree(1)).to eq 'B♭4' }
    specify { expect(scale.degree(2)).to eq 'C5' }
  end

  describe '#pitches' do
    specify { expect(Scale.get('B♭', :dorian).pitch_names).to eq %w[B♭4 C5 D♭5 E♭5 F5 G5 A♭5 B♭5] }

    context 'descending' do
      specify { expect(Scale.get('C5', :melodic_minor).pitch_names(direction: :descending)).to eq %w[C5 B♭4 A♭4 G4 F4 E♭4 D4 C4] }
    end

    context 'ascending and descending' do
      specify { expect(Scale.get('C4', :melodic_minor).pitch_names(direction: :both)).to eq %w[C4 D4 E♭4 F4 G4 A4 B4 C5 B♭4 A♭4 G4 F4 E♭4 D4 C4] }
    end

    context 'two octaves up and down' do
      specify do
        expect(
          Scale.get('C4', :melodic_minor).pitch_names(direction: :both, octaves: 2)
        ).to eq %w[C4 D4 E♭4 F4 G4 A4 B4 C5 D5 E♭5 F5 G5 A5 B5 C6 B♭5 A♭5 G5 F5 E♭5 D5 C5 B♭4 A♭4 G4 F4 E♭4 D4 C4]
      end
    end
  end
end
