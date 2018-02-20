# frozen_string_literal: true

require 'spec_helper'

describe HeadMusic::Style::Annotations::RecoverLargeLeaps do
  let(:composition) { Composition.new(key_signature: 'D dorian') }
  let(:voice) { Voice.new(composition: composition) }
  subject { described_class.new(voice) }

  context 'with no notes' do
    it { is_expected.to be_adherent }
  end

  context 'with leaps' do
    context 'recovered by step in the opposite direction' do
      before do
        %w[D4 F4 E4 D4 G4 F4 A4 G4 F4 E4 D4].each.with_index(1) do |pitch, bar|
          voice.place("#{bar}:1", :whole, pitch)
        end
      end

      it { is_expected.to be_adherent }
    end

    context 'recovered by skip in the opposite direction' do
      before do
        %w[D4 F4 E4 D4 G4 E4 A4 G4 F4 E4 D4].each.with_index(1) do |pitch, bar|
          voice.place("#{bar}:1", :whole, pitch)
        end
      end

      its(:fitness) { is_expected.to eq PENALTY_FACTOR }
      its(:first_mark_code) { is_expected.to eq '4:1:000 to 7:1:000' }
    end

    context 'not recovered, not spelling a triad' do
      before do
        %w[D4 F4 E4 D4 G4 A4 G4 F4 E4 D4].each.with_index(1) do |pitch, bar|
          voice.place("#{bar}:1", :whole, pitch)
        end
      end

      its(:fitness) { is_expected.to eq PENALTY_FACTOR }
      its(:first_mark_code) { is_expected.to eq '4:1:000 to 7:1:000' }
    end

    context 'not recovered, but spelling a triad' do
      before do
        %w[D4 F4 E4 D4 G4 B4 G4 F4 E4 D4].each.with_index(1) do |pitch, bar|
          voice.place("#{bar}:1", :whole, pitch)
        end
      end

      it { is_expected.to be_adherent }
    end

    context 'when the leap is recovered by skip spelling a triad' do
      let(:composition) { Composition.new(key_signature: 'F lydian') }

      before do
        # FUX example
        %w[F4 G4 A4 F4 D4 E4 F4 C5 A4 F4 G4 F4].each.with_index(1) do |pitch, bar|
          voice.place("#{bar}:1", :whole, pitch)
        end
      end

      it { is_expected.to be_adherent }
      its(:first_mark_code) { is_expected.to eq nil }
    end
  end
end
