# frozen_string_literal: true

require 'spec_helper'

describe HeadMusic::KeySignature do
  context '.new' do
    subject(:key_signature) { described_class.new(tonic, scale_type) }

    context 'when given an instance' do
      let(:instance) { described_class.get('F♯ major') }

      it 'returns that instance' do
        expect(described_class.get(instance)).to be instance
      end
    end

    context 'when given only a tonic' do
      let(:tonic) { 'E♭' }
      let(:scale_type) { nil }

      it 'assumes a major key' do
        expect(key_signature).to eq 'E♭ major'
        expect(key_signature.num_flats).to eq 3
        expect(key_signature.signs).to eq ['B♭', 'E♭', 'A♭']
      end
    end

    context 'when given the major scale_type' do
      let(:scale_type) { :major }

      context 'in the key of C major' do
        let(:tonic) { HeadMusic::Spelling.get('C') }

        specify { expect(key_signature.num_sharps).to eq 0 }
        specify { expect(key_signature.num_flats).to eq 0 }
        specify { expect(key_signature.signs).to eq [] }
      end

      context 'in the key of E♭ major' do
        let(:tonic) { HeadMusic::Spelling.get('E♭') }

        specify { expect(key_signature.num_flats).to eq 3 }
        specify { expect(key_signature.signs).to eq ['B♭', 'E♭', 'A♭'] }
      end

      context 'in the key of F♯ major' do
        let(:tonic) { HeadMusic::Spelling.get('F♯') }

        specify { expect(key_signature.num_sharps).to eq 6 }
        specify { expect(key_signature.signs).to eq %w[F♯ C♯ G♯ D♯ A♯ E♯] }
      end

      context 'in the key of G♭ major' do
        let(:tonic) { HeadMusic::Spelling.get('G♭') }

        specify { expect(key_signature.signs).to eq %w[B♭ E♭ A♭ D♭ G♭ C♭] }
      end
    end

    context 'when given the minor scale_type' do
      let(:scale_type) { :minor }

      context 'in the key of C minor' do
        let(:tonic) { HeadMusic::Spelling.get('C') }

        specify { expect(key_signature.num_flats).to eq 3 }
        specify { expect(key_signature.signs).to eq ['B♭', 'E♭', 'A♭'] }
      end

      context 'in the key of B minor' do
        let(:tonic) { HeadMusic::Spelling.get('B') }

        specify { expect(key_signature.num_sharps).to eq 2 }

        specify { expect(key_signature.signs).to eq ['F♯', 'C♯'] }
      end
    end

    context 'when given the dorian scale_type' do
      let(:scale_type) { :dorian }
      let(:tonic) { 'C' }

      specify { expect(key_signature.num_flats).to eq 2 }

      specify { expect(key_signature.flats).to eq ['B♭', 'E♭'] }
      specify { expect(key_signature.signs).to eq ['B♭', 'E♭'] }
    end
  end

  describe 'equality' do
    context 'given a major key' do
      subject(:key_signature) { described_class.new(tonic, scale_type) }
      let(:tonic) { 'E♭' }
      let(:scale_type) { :major }

      it 'is equal to itself' do
        expect(key_signature).to eq described_class.get('E♭ major')
      end

      it 'is not equal to other major keys' do
        expect(key_signature).not_to eq described_class.get('E major')
        expect(key_signature).not_to eq described_class.get('B♭ major')
      end

      it 'is equal to the relative minor' do
        expect(key_signature).to eq described_class.get('C minor')
      end

      it 'is equal to the relative modes' do
        expect(key_signature).to eq described_class.get('Eb ionian')
        expect(key_signature).to eq described_class.get('F dorian')
        expect(key_signature).to eq described_class.get('G phrygian')
        expect(key_signature).to eq described_class.get('Ab lydian')
        expect(key_signature).to eq described_class.get('Bb mixolydian')
        expect(key_signature).to eq described_class.get('C aeolian')
        expect(key_signature).to eq described_class.get('D locrian')
      end

      it 'is not equal to modes with the wrong final' do
        expect(key_signature).not_to eq described_class.get('C ionian')
        expect(key_signature).not_to eq described_class.get('Eb dorian')
        expect(key_signature).not_to eq described_class.get('Eb phrygian')
        expect(key_signature).not_to eq described_class.get('Eb lydian')
        expect(key_signature).not_to eq described_class.get('Eb mixolydian')
        expect(key_signature).not_to eq described_class.get('Eb aeolian')
        expect(key_signature).not_to eq described_class.get('Eb locrian')
      end
    end

    context 'given a pentatonic scale type' do
      subject(:key_signature) { described_class.new(tonic, scale_type) }
      let(:tonic) { 'D' }
      let(:scale_type) { :major_pentatonic }

      specify { expect(key_signature.num_sharps).to eq 2 }
      specify { expect(key_signature.signs).to eq %w[F♯ C♯] }
    end
  end

  describe '♯spellings' do
    specify { expect(described_class.get('D major').spellings).to eq %w[D E F♯ G A B C♯] }
  end
end
