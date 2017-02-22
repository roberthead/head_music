require 'spec_helper'

describe Scale do
  describe 'default scale' do
    specify { expect(Scale.get('G').spellings).to eq %w[G A B C D E F# G] }
  end

  describe 'spelling' do
    describe 'accuracy' do
      specify { expect(Scale.get('D4', :major).spellings).to eq %w[D E F# G A B C# D] }
      specify { expect(Scale.get('C#3', :major).spellings).to eq %w[C# D# E# F# G# A# B# C#] }
      specify { expect(Scale.get('F#3', :natural_minor).spellings).to eq %w[F# G# A B C# D E F#] }
      specify { expect(Scale.get('F#3', :harmonic_minor).spellings).to eq %w[F# G# A B C# D E# F#] }
      specify { expect(Scale.get('F#3', :melodic_minor).spellings).to eq %w[F# G# A B C# D# E# F#] }
      specify { expect(Scale.get('D', :harmonic_minor).spellings).to eq %w[D E F G A Bb C# D] }
      specify { expect(Scale.get('Bb', :dorian).spellings).to eq %w[Bb C Db Eb F G Ab Bb] }
      specify { expect(Scale.get('B', :locrian).spellings).to eq %w[B C D E F G A B] }
      specify { expect(Scale.get('C', :minor_pentatonic).spellings).to eq %w[C Eb F G Bb C] }
      specify { expect(Scale.get('F#', :major_pentatonic).spellings).to eq %w[F# G# A# C# D# F#] }
      specify { expect(Scale.get('Gb', :major_pentatonic).spellings).to eq %w[Gb Ab Bb Db Eb Gb] }
      specify { expect(Scale.get('F', :minor_pentatonic).spellings).to eq %w[F Ab Bb C Eb F] }
      specify { expect(Scale.get('C', :whole_tone).spellings).to eq %w[C D E F# G# A# C] }
      specify { expect(Scale.get('C#', :whole_tone).spellings).to eq %w[C# D# F G A B C#] }
      specify { expect(Scale.get('Db', :whole_tone).spellings).to eq %w[Db Eb F G A B Db] }
      specify { expect(Scale.get('C', :chromatic).spellings).to eq %w[C C# D D# E F F# G G# A A# B C] }
      specify { expect(Scale.get('C#', :chromatic).spellings).to eq %w[C# D D# E F F# G G# A A# B C C#] }
    end

    describe 'options' do
      subject(:scale) { Scale.get('C', :minor_pentatonic) }

      specify do
        expect(scale.spellings(direction: :both, octaves: 2)).to eq %w[C Eb F G Bb C Eb F G Bb C Bb G F Eb C Bb G F Eb C]
      end
    end
  end

  describe '#degree' do
    let(:scale) { Scale.get('Bb', :major) }

    specify { expect(scale.degree(1)).to eq 'Bb4' }
    specify { expect(scale.degree(2)).to eq 'C5' }
  end

  describe '#pitches' do
    specify { expect(Scale.get('Bb', :dorian).pitch_names).to eq %w[Bb4 C5 Db5 Eb5 F5 G5 Ab5 Bb5] }

    context 'descending' do
      specify { expect(Scale.get('C5', :melodic_minor).pitch_names(direction: :descending)).to eq %w[C5 Bb4 Ab4 G4 F4 Eb4 D4 C4] }
    end

    context 'ascending and descending' do
      specify { expect(Scale.get('C4', :melodic_minor).pitch_names(direction: :both)).to eq %w[C4 D4 Eb4 F4 G4 A4 B4 C5 Bb4 Ab4 G4 F4 Eb4 D4 C4] }
    end

    context 'two octaves up and down' do
      specify {
        expect(
          Scale.get('C4', :melodic_minor).pitch_names(direction: :both, octaves: 2)
        ).to eq %w[C4 D4 Eb4 F4 G4 A4 B4 C5 D5 Eb5 F5 G5 A5 B5 C6 Bb5 Ab5 G5 F5 Eb5 D5 C5 Bb4 Ab4 G4 F4 Eb4 D4 C4]
      }
    end
  end
end
