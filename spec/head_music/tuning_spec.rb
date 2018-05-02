# frozen_string_literal: true

require 'spec_helper'

describe HeadMusic::Tuning do
  it { is_expected.to respond_to(:reference_pitch) }
  it { is_expected.to respond_to(:reference_frequency) }

  context 'when not given any arguments' do
    subject { described_class.new }

    its(:reference_pitch) { is_expected.to eq 'A4' }
    its(:reference_frequency) { is_expected.to eq 440.0 }

    describe '#frequency_for' do
      let(:tuning) { described_class.new }

      subject { tuning.frequency_for(pitch_name) }

      context 'C4' do
        let(:pitch_name) { 'C4' }

        it { is_expected.to be_within(0.1).of(261.6) }
      end

      context 'A3' do
        let(:pitch_name) { 'A3' }

        it { is_expected.to be_within(0.01).of(220.0) }
      end

      context 'A5' do
        let(:pitch_name) { 'A5' }

        it { is_expected.to be_within(0.01).of(880.0) }
      end

      context 'C0' do
        let(:pitch_name) { 'C0' }

        it { is_expected.to be_within(0.1).of(16.3) }
      end
    end
  end
end
