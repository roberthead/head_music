require 'spec_helper'

describe Scale do
  context 'when the scale type is not specified' do
    subject(:scale) { Scale.get('G') }

    it 'defaults to major' do
      expect(scale.pitch_names).to eq %w[G A B C D E F# G]
    end
  end

  context 'for D major' do
    subject(:scale) { Scale.get("D4", :major) }

    its(:pitch_names) { are_expected.to eq %w[D E F# G A B C# D] }
  end

  context 'for F# minor' do
    subject(:scale) { Scale.get("F#3", :minor) }

    its(:pitch_names) { are_expected.to eq %w[F# G# A B C# D E F#] }
  end

  context 'for F# melodic minor' do
    subject(:scale) { Scale.get("F#3", :melodic_minor) }

    its(:pitch_names) { are_expected.to eq %w[F# G# A B C# D# E# F#] }
  end

  xcontext 'for F# harmonic minor' do
    subject(:scale) { Scale.get("F#3", :harmonic_minor) }

    its(:pitch_names) { are_expected.to eq %w[F# G# A B C# D E# F#] }
  end

  context 'for Bb dorian' do
    subject(:scale) { Scale.get("Bb", :dorian) }

    its(:pitch_names) { are_expected.to eq %w[Bb C Db Eb F G Ab Bb] }
  end

  context 'for Bb dorian' do
    subject(:scale) { Scale.get("Bb", :dorian) }

    its(:pitch_names) { are_expected.to eq %w[Bb C Db Eb F G Ab Bb] }
  end

  xcontext 'for C whole tone' do
    subject(:scale) { Scale.get("C", :whole_tone) }

    its(:pitch_names) { are_expected.to eq %w[C D E F# G# A# C] } # -> ["C", "D", "E", "F#", "G#", "A#", "B#"]
  end
end
