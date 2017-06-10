require 'spec_helper'

describe Motion do
  let(:composition) { Composition.new }
  let(:upper_voice) do
    composition.add_voice(role: :melody).tap do |voice|
      upper_voice_pitches.each.with_index(1) do |pitch, bar|
        voice.place("#{bar}:1:0", :whole, pitch)
      end
    end
  end
  let(:lower_voice) do
    composition.add_voice(role: :bass).tap do |voice|
      lower_voice_pitches.each.with_index(1) do |pitch, bar|
        voice.place("#{bar}:1:0", :whole, pitch)
      end
    end
  end

  let(:first_harmonic_interval) { HarmonicInterval.new(lower_voice, upper_voice, "1:1") }
  let(:second_harmonic_interval) { HarmonicInterval.new(lower_voice, upper_voice, "2:1") }

  subject { Motion.new(first_harmonic_interval, second_harmonic_interval) }

  context 'when the lower voice repeats the note' do
    let(:lower_voice_pitches) { %w[C4 C4] }

    context 'when the upper voice repeats the note' do
      let(:upper_voice_pitches) { %w[E4 E4] }

      it { is_expected.to be_repetition }
      it { is_expected.not_to be_oblique }
      it { is_expected.not_to be_similar }
      it { is_expected.not_to be_parallel }
      it { is_expected.not_to be_direct }
      it { is_expected.not_to be_contrary }
    end

    context 'when the upper voice rises' do
      let(:upper_voice_pitches) { %w[E4 A4] }

      it { is_expected.not_to be_repetition }
      it { is_expected.to be_oblique }
      it { is_expected.not_to be_similar }
      it { is_expected.not_to be_parallel }
      it { is_expected.not_to be_direct }
      it { is_expected.not_to be_contrary }
    end

    context 'when the upper voice falls' do
      let(:upper_voice_pitches) { %w[A4 G4] }

      it { is_expected.not_to be_repetition }
      it { is_expected.to be_oblique }
      it { is_expected.not_to be_similar }
      it { is_expected.not_to be_parallel }
      it { is_expected.not_to be_direct }
      it { is_expected.not_to be_contrary }
    end
  end

  context 'when the lower voice rises' do
    let(:lower_voice_pitches) { %w[C4 D4] }

    context 'when the upper voice repeats the note' do
      let(:upper_voice_pitches) { %w[A4 A4] }

      it { is_expected.not_to be_repetition }
      it { is_expected.to be_oblique }
      it { is_expected.not_to be_similar }
      it { is_expected.not_to be_parallel }
      it { is_expected.not_to be_direct }
      it { is_expected.not_to be_contrary }
    end

    context 'when the upper voice rises' do
      context 'by the same number of steps' do
        let(:upper_voice_pitches) { %w[E4 F4] }

        it { is_expected.not_to be_repetition }
        it { is_expected.not_to be_oblique }
        it { is_expected.not_to be_similar }
        it { is_expected.to be_parallel }
        it { is_expected.to be_direct }
        it { is_expected.not_to be_contrary }
      end

      context 'by a different number of steps' do
        let(:upper_voice_pitches) { %w[E4 A4] }

        it { is_expected.not_to be_repetition }
        it { is_expected.not_to be_oblique }
        it { is_expected.to be_similar }
        it { is_expected.not_to be_parallel }
        it { is_expected.to be_direct }
        it { is_expected.not_to be_contrary }
      end
    end

    context 'when the upper voice falls' do
      let(:upper_voice_pitches) { %w[A4 F4] }

      it { is_expected.not_to be_repetition }
      it { is_expected.not_to be_oblique }
      it { is_expected.not_to be_similar }
      it { is_expected.not_to be_parallel }
      it { is_expected.not_to be_direct }
      it { is_expected.to be_contrary }
    end
  end

  context 'when the lower voice falls' do
    let(:lower_voice_pitches) { %w[C4 B3] }

    context 'when the upper voice repeats the note' do
      let(:upper_voice_pitches) { %w[G4 G4] }

      it { is_expected.not_to be_repetition }
      it { is_expected.to be_oblique }
      it { is_expected.not_to be_similar }
      it { is_expected.not_to be_parallel }
      it { is_expected.not_to be_direct }
      it { is_expected.not_to be_contrary }
    end

    context 'when the upper voice rises' do
      let(:upper_voice_pitches) { %w[E4 G4] }

      it { is_expected.not_to be_repetition }
      it { is_expected.not_to be_oblique }
      it { is_expected.not_to be_similar }
      it { is_expected.not_to be_parallel }
      it { is_expected.not_to be_direct }
      it { is_expected.to be_contrary }
    end

    context 'when the upper voice falls' do
      context 'by the same number of steps' do
        let(:upper_voice_pitches) { %w[A4 G4] }

        it { is_expected.not_to be_repetition }
        it { is_expected.not_to be_oblique }
        it { is_expected.not_to be_similar }
        it { is_expected.to be_parallel }
        it { is_expected.to be_direct }
        it { is_expected.not_to be_contrary }
      end

      context 'by a different number of steps' do
        let(:upper_voice_pitches) { %w[G4 D4] }

        it { is_expected.not_to be_repetition }
        it { is_expected.not_to be_oblique }
        it { is_expected.to be_similar }
        it { is_expected.not_to be_parallel }
        it { is_expected.to be_direct }
        it { is_expected.not_to be_contrary }
      end
    end
  end
end
