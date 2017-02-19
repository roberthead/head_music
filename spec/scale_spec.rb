require 'spec_helper'

describe Scale do
  context 'when the scale type is not specified' do
    subject(:scale) { Scale.get('G') }

    it 'defaults to major' do
      expect(scale.pitch_names).to eq %w[G A B C D E F# G]
    end
  end

  context 'for D major' do
    subject(:scale) { Scale.get('D4', :major) }

    its(:pitch_names) { are_expected.to eq %w[D E F# G A B C# D] }
  end

  context 'for F# minor' do
    subject(:scale) { Scale.get('F#3', :minor) }

    its(:pitch_names) { are_expected.to eq %w[F# G# A B C# D E F#] }
  end

  context 'for C# major' do
    subject(:scale) { Scale.get('C#3', :major) }

    its(:pitch_names) { are_expected.to eq %w[C# D# E# F# G# A# B# C#] }
  end

  context 'for F# melodic minor' do
    subject(:scale) { Scale.get('F#3', :melodic_minor) }

    its(:pitch_names) { are_expected.to eq %w[F# G# A B C# D# E# F#] }
  end

  context 'for F# harmonic minor' do
    subject(:scale) { Scale.get('F#3', :harmonic_minor) }

    its(:pitch_names) { are_expected.to eq %w[F# G# A B C# D E# F#] }
  end

  context 'for D harmonic minor' do
    subject(:scale) { Scale.get('D', :harmonic_minor) }

    its(:pitch_names) { are_expected.to eq %w[D E F G A Bb C# D] }
  end

  context 'for Bb dorian' do
    subject(:scale) { Scale.get('Bb', :dorian) }

    its(:pitch_names) { are_expected.to eq %w[Bb C Db Eb F G Ab Bb] }
  end

  context 'for B locrian' do
    subject(:scale) { Scale.get('B', :locrian) }

    its(:pitch_names) { are_expected.to eq %w[B C D E F G A B] }
  end

  context 'for C minor pentatonic' do
    subject(:scale) { Scale.get('C', :minor_pentatonic) }

    its(:pitch_names) { are_expected.to eq %w[C Eb F G Bb C] }
  end

  context 'for F# major pentatonic' do
    subject(:scale) { Scale.get('F#', :major_pentatonic) }

    its(:pitch_names) { are_expected.to eq %w[F# G# A# C# D# F#] }
  end

  context 'for Gb major pentatonic' do
    subject(:scale) { Scale.get('Gb', :major_pentatonic) }

    its(:pitch_names) { are_expected.to eq %w[Gb Ab Bb Db Eb Gb] }
  end

  context 'for F minor pentatonic' do
    subject(:scale) { Scale.get('F', :minor_pentatonic) }

    its(:pitch_names) { are_expected.to eq %w[F Ab Bb C Eb F] }
  end

  context 'for C whole tone' do
    subject(:scale) { Scale.get('C', :whole_tone) }

    its(:pitch_names) { are_expected.to eq %w[C D E F# G# A# C] }
  end

  context 'for Db whole tone' do
    subject(:scale) { Scale.get('Db', :whole_tone) }

    its(:pitch_names) { are_expected.to eq %w[Db Eb F G A B Db] }
  end

  context 'for C chromatic' do
    subject(:scale) { Scale.get('C', :chromatic) }

    its(:pitch_names) { are_expected.to eq %w[C C# D D# E F F# G G# A A# B C] }
  end

  context 'for C# chromatic' do
    subject(:scale) { Scale.get('C#', :chromatic) }

    its(:pitch_names) { are_expected.to eq %w[C# D D# E F F# G G# A A# B C C#] }
  end
end
