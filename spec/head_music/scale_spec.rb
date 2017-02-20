require 'spec_helper'

describe Scale do
  context 'when the scale type is not specified' do
    subject(:scale) { Scale.get('G') }

    it 'defaults to major' do
      expect(scale.pitch_names).to eq %w[G A B C D E F# G]
    end
  end

  specify { expect(Scale.get('D4', :major).pitch_names).to eq %w[D E F# G A B C# D] }
  specify { expect(Scale.get('C#3', :major).pitch_names).to eq %w[C# D# E# F# G# A# B# C#] }
  specify { expect(Scale.get('F#3', :natural_minor).pitch_names).to eq %w[F# G# A B C# D E F#] }
  specify { expect(Scale.get('F#3', :harmonic_minor).pitch_names).to eq %w[F# G# A B C# D E# F#] }
  specify { expect(Scale.get('F#3', :melodic_minor).pitch_names).to eq %w[F# G# A B C# D# E# F#] }
  specify { expect(Scale.get('D', :harmonic_minor).pitch_names).to eq %w[D E F G A Bb C# D] }
  specify { expect(Scale.get('Bb', :dorian).pitch_names).to eq %w[Bb C Db Eb F G Ab Bb] }
  specify { expect(Scale.get('B', :locrian).pitch_names).to eq %w[B C D E F G A B] }
  specify { expect(Scale.get('C', :minor_pentatonic).pitch_names).to eq %w[C Eb F G Bb C] }
  specify { expect(Scale.get('F#', :major_pentatonic).pitch_names).to eq %w[F# G# A# C# D# F#] }
  specify { expect(Scale.get('Gb', :major_pentatonic).pitch_names).to eq %w[Gb Ab Bb Db Eb Gb] }
  specify { expect(Scale.get('F', :minor_pentatonic).pitch_names).to eq %w[F Ab Bb C Eb F] }
  specify { expect(Scale.get('C', :whole_tone).pitch_names).to eq %w[C D E F# G# A# C] }
  specify { expect(Scale.get('C#', :whole_tone).pitch_names).to eq %w[C# D# F G A B C#] }
  specify { expect(Scale.get('Db', :whole_tone).pitch_names).to eq %w[Db Eb F G A B Db] }
  specify { expect(Scale.get('C', :chromatic).pitch_names).to eq %w[C C# D D# E F F# G G# A A# B C] }
  specify { expect(Scale.get('C#', :chromatic).pitch_names).to eq %w[C# D D# E F F# G G# A A# B C C#] }
end
