require 'spec_helper'

describe KeySignature do
  let(:scale_type) { nil }
  subject(:key_signature) { KeySignature.new(tonic, scale_type) }

  context 'in the key of C major' do
    let(:tonic) { Spelling.get('C') }

    specify { expect(key_signature.num_sharps).to eq 0 }
    specify { expect(key_signature.num_flats).to eq 0 }
    specify { expect(key_signature.sharps_or_flats).to eq [] }
  end

  context 'in the key of Eb major' do
    let(:tonic) { Spelling.get('Eb') }

    specify { expect(key_signature.num_sharps).to eq 9 }
    specify { expect(key_signature.num_flats).to eq 3 }

    specify { expect(key_signature.flats).to eq ['Bb', 'Eb', 'Ab'] }
    specify { expect(key_signature.sharps_or_flats).to eq ['Bb', 'Eb', 'Ab'] }
  end

  context 'in the key of F# major' do
    let(:tonic) { Spelling.get('F#') }

    specify { expect(key_signature.num_sharps).to eq 6 }
    specify { expect(key_signature.num_flats).to eq 6 }

    specify { expect(key_signature.flats).to eq %w{Bb Eb Ab Db Gb Cb} }
    specify { expect(key_signature.sharps_or_flats).to eq %w{F# C# G# D# A# E#} }
  end

  context 'in the key of Gb major' do
    let(:tonic) { Spelling.get('Gb') }

    specify { expect(key_signature.sharps_or_flats).to eq %w[Bb Eb Ab Db Gb Cb] }
  end

  context 'in the key of C minor' do
    let(:scale_type) { :minor }
    let(:tonic) { Spelling.get('C') }

    specify { expect(key_signature.num_sharps).to eq 9 }
    specify { expect(key_signature.num_flats).to eq 3 }

    specify { expect(key_signature.flats).to eq ['Bb', 'Eb', 'Ab'] }
    specify { expect(key_signature.sharps_or_flats).to eq ['Bb', 'Eb', 'Ab'] }
  end

  context 'in the key of B minor' do
    let(:scale_type) { :minor }
    let(:tonic) { Spelling.get('B') }

    specify { expect(key_signature.num_sharps).to eq 2 }
    specify { expect(key_signature.num_flats).to eq 10 }

    specify { expect(key_signature.sharps_or_flats).to eq ['F#', 'C#'] }
  end
end
