# frozen_string_literal: true

require 'spec_helper'

describe HeadMusic::HarmonicInterval do
  let(:composition) { HeadMusic::Composition.new }
  let!(:high_voice) { composition.add_voice(role: :melody) }
  let!(:low_voice) { composition.add_voice(role: :bass_line) }
  let(:position) { HeadMusic::Position.new(composition, '2:1') }
  let!(:high_note) { high_voice.place(position, :quarter, 'D4') }
  let!(:low_note) { low_voice.place(position, :whole, 'F3') }
  subject(:harmonic_interval) { described_class.new(high_voice, low_voice, position) }

  its(:position) { is_expected.to eq '2:1' }

  it 'assigns the voices' do
    expect(harmonic_interval.voices).to match([high_voice, low_voice])
  end

  it 'assigns the notes, lowest to highest' do
    expect(harmonic_interval.notes).to eq([low_note, high_note])
  end

  its(:pitches) { are_expected.to eq(%w[F3 D4]) }
  its(:upper_pitch) { is_expected.to eq 'D4' }
  its(:lower_pitch) { is_expected.to eq 'F3' }

  its(:functional_interval) { is_expected.to eq 'major sixth' }

  its(:to_s) { is_expected.to eq 'major sixth at 2:1:000' }
end
