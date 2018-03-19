# frozen_string_literal: true

require 'spec_helper'

describe HeadMusic::Style::Guidelines::StartOnPerfectConsonance do
  let(:composition) { HeadMusic::Composition.new(key_signature: 'C major') }
  let!(:cantus_firmus) do
    composition.add_voice(role: 'cantus firmus').tap do |voice|
      voice.place('1:1', :whole, 'C4')
    end
  end
  let(:voice) { composition.add_voice(role: 'counterpoint') }

  subject { described_class.new(voice) }

  context 'with no notes' do
    it { is_expected.to be_adherent }
  end

  context 'when the first note is a perfect unison' do
    before do
      voice.place('1:1', :whole, 'C4')
    end

    it { is_expected.to be_adherent }
  end

  context 'when the first note is an augmented unison' do
    before do
      voice.place('1:1', :whole, 'C#4')
    end

    its(:fitness) { is_expected.to be <= HeadMusic::PENALTY_FACTOR }
  end

  context 'when the first note is a perfect fifth above' do
    before do
      voice.place('1:1', :whole, 'G4')
    end

    it { is_expected.to be_adherent }
  end

  context 'when the first note is a perfect octave above' do
    before do
      voice.place('1:1', :whole, 'C5')
    end

    it { is_expected.to be_adherent }
  end

  context 'when the first note is a perfect fifth below' do
    before do
      voice.place('1:1', :whole, 'F3')
    end

    its(:fitness) { is_expected.to be < 1 }
  end

  context 'when the first note is the dominant below' do
    before do
      voice.place('1:1', :whole, 'G3')
    end

    its(:fitness) { is_expected.to be < 1 }
  end

  context 'when the first note is an imperfect consonance' do
    before do
      voice.place('1:1', :whole, 'A')
    end

    its(:fitness) { is_expected.to be < 1 }
  end

  context 'when the first note is a dissonance' do
    before do
      voice.place('1:1', :whole, 'A')
    end

    its(:fitness) { is_expected.to be <= HeadMusic::PENALTY_FACTOR }
  end

  context 'when the intervals are compound' do
    let(:composition) { HeadMusic::Composition.new(key_signature: 'G mixolydian') }
    let!(:cantus_firmus) do
      composition.add_voice(role: 'cantus firmus').tap do |voice|
        cantus_firmus_pitches.each.with_index(1) do |pitch, bar|
          voice.place("#{bar}:1:0", :whole, pitch)
        end
      end
    end
    let(:voice) do
      composition.add_voice(role: 'counterpoint').tap do |voice|
        counterpoint_pitches.each.with_index(1) do |pitch, bar|
          voice.place("#{bar}:1:0", :whole, pitch)
        end
      end
    end

    let(:cantus_firmus_pitches) { %w[G3 A3 B3 A3 C B3 A3 G3] }
    let(:counterpoint_pitches) { %w[D5 C5 G A G G F# G] }

    it { is_expected.to be_adherent }
  end
end
