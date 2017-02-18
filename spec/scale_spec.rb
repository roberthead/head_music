require 'spec_helper'

describe Scale do
  describe 'major scale' do
    subject(:scale) { Scale.major }

    describe 'spellings' do
      specify { expect(scale.in('D')).to eq %w{D E F# G A B C# D} }
      specify { expect(scale.in('Ab')).to eq %w{Ab Bb C Db Eb F G Ab} }
    end
  end

  describe 'minor scale' do
    subject(:scale) { Scale.minor }

    specify { expect(scale.in('D')).to eq %w{D E F G A Bb C D} }
    specify { expect(scale.in('Ab')).to eq %w{Ab Bb Cb Db Eb Fb Gb Ab} }
  end

  describe 'minor pentatonic scale' do
    subject(:scale) { Scale.minor_pentatonic }

    specify { expect(scale.in('C')).to eq %w{C Eb F G Bb C} }
    specify { expect(scale.in('Bb')).to eq %w{Bb Db Eb F Ab Bb} }
  end
end
