require 'spec_helper'

describe KeySignature do
  context '.new' do
    subject(:key_signature) { KeySignature.new(tonic, scale_type) }

    context 'when given an instance' do
      let(:instance) { described_class.get('F# major') }

      it 'returns that instance' do
        expect(described_class.get(instance)).to be instance
      end
    end

    context 'when given only a tonic' do
      let(:tonic) { 'Eb' }
      let(:scale_type) { nil }

      it 'assumes a major key' do
        expect(key_signature).to eq 'Eb major'
        expect(key_signature.num_flats).to eq 3
        expect(key_signature.sharps_or_flats).to eq ['Bb', 'Eb', 'Ab']
      end
    end

    context 'when given the major scale_type' do
      let(:scale_type) { :major }

      context 'in the key of C major' do
        let(:tonic) { Spelling.get('C') }

        specify { expect(key_signature.num_sharps).to eq 0 }
        specify { expect(key_signature.num_flats).to eq 0 }
        specify { expect(key_signature.sharps_or_flats).to eq [] }
      end

      context 'in the key of Eb major' do
        let(:tonic) { Spelling.get('Eb') }

        specify { expect(key_signature.num_flats).to eq 3 }
        specify { expect(key_signature.sharps_or_flats).to eq ['Bb', 'Eb', 'Ab'] }
      end

      context 'in the key of F# major' do
        let(:tonic) { Spelling.get('F#') }

        specify { expect(key_signature.num_sharps).to eq 6 }
        specify { expect(key_signature.sharps_or_flats).to eq %w{F# C# G# D# A# E#} }
      end

      context 'in the key of Gb major' do
        let(:tonic) { Spelling.get('Gb') }

        specify { expect(key_signature.sharps_or_flats).to eq %w[Bb Eb Ab Db Gb Cb] }
      end
    end

    context 'when given the minor scale_type' do
      let(:scale_type) { :minor }

      context 'in the key of C minor' do
        let(:tonic) { Spelling.get('C') }

        specify { expect(key_signature.num_flats).to eq 3 }
        specify { expect(key_signature.sharps_or_flats).to eq ['Bb', 'Eb', 'Ab'] }
      end

      context 'in the key of B minor' do
        let(:tonic) { Spelling.get('B') }

        specify { expect(key_signature.num_sharps).to eq 2 }

        specify { expect(key_signature.sharps_or_flats).to eq ['F#', 'C#'] }
      end
    end

    context 'when given the dorian scale_type' do
      let(:scale_type) { :dorian }
      let(:tonic) { 'C' }

      specify { expect(key_signature.num_flats).to eq 2 }

      specify { expect(key_signature.flats).to eq ['Bb', 'Eb'] }
      specify { expect(key_signature.sharps_or_flats).to eq ['Bb', 'Eb'] }
    end
  end

  describe 'equality' do
    context 'given a major key' do
      subject(:key_signature) { KeySignature.new(tonic, scale_type) }
      let(:tonic) { 'Eb' }
      let(:scale_type) { :major }

      it 'is equal to itself' do
        expect(key_signature).to eq KeySignature.get('Eb major')
      end

      it 'is not equal to other major keys' do
        expect(key_signature).not_to eq KeySignature.get('E major')
        expect(key_signature).not_to eq KeySignature.get('Bb major')
      end

      it 'is equal to the relative minor' do
        expect(key_signature).to eq KeySignature.get('C minor')
      end

      it 'is equal to the relative modes' do
        expect(key_signature).to eq KeySignature.get('Eb ionian')
        expect(key_signature).to eq KeySignature.get('F dorian')
        expect(key_signature).to eq KeySignature.get('G phrygian')
        expect(key_signature).to eq KeySignature.get('Ab lydian')
        expect(key_signature).to eq KeySignature.get('Bb mixolydian')
        expect(key_signature).to eq KeySignature.get('C aeolian')
        expect(key_signature).to eq KeySignature.get('D locrian')
      end

      it 'is not equal to modes with the wrong final' do
        expect(key_signature).not_to eq KeySignature.get('C ionian')
        expect(key_signature).not_to eq KeySignature.get('Eb dorian')
        expect(key_signature).not_to eq KeySignature.get('Eb phrygian')
        expect(key_signature).not_to eq KeySignature.get('Eb lydian')
        expect(key_signature).not_to eq KeySignature.get('Eb mixolydian')
        expect(key_signature).not_to eq KeySignature.get('Eb aeolian')
        expect(key_signature).not_to eq KeySignature.get('Eb locrian')
      end
    end

    context 'given a pentatonic scale type' do
      subject(:key_signature) { KeySignature.new(tonic, scale_type) }
      let(:tonic) { 'D' }
      let(:scale_type) { :major_pentatonic }

      specify { expect(key_signature.num_sharps).to eq 2 }
      specify { expect(key_signature.sharps_or_flats).to eq %w{F# C#} }
    end
  end

  describe '#spellings' do
    specify { expect(KeySignature.get('D major').spellings).to eq %w[D E F# G A B C#] }
  end
end
