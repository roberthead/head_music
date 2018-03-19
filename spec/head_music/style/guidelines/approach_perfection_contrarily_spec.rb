# frozen_string_literal: true

require 'spec_helper'

describe HeadMusic::Style::Guidelines::ApproachPerfectionContrarily do
  let(:composition) { HeadMusic::Composition.new(key_signature: 'C major') }
  let(:cantus_firmus_pitches) { [] }
  let!(:cantus_firmus) do
    composition.add_voice(role: :cantus_firmus).tap do |voice|
      cantus_firmus_pitches.each.with_index(1) do |pitch, bar|
        voice.place("#{bar}:1:0", :whole, pitch)
      end
    end
  end
  let(:counterpoint) do
    composition.add_voice(role: :counterpoint).tap do |voice|
      counterpoint_pitches.each.with_index(1) do |pitch, bar|
        voice.place("#{bar}:1:0", :whole, pitch)
      end
    end
  end

  subject { described_class.new(counterpoint) }

  context 'with no notes' do
    let(:counterpoint_pitches) { [] }

    it { is_expected.to be_adherent }
  end

  context 'with perfect harmonic intervals' do
    context 'approached by contrary motion' do
      let(:counterpoint_pitches) { %w[C5 B A] }
      let(:cantus_firmus_pitches) { %w[C E F] }

      it { is_expected.to be_adherent }
    end

    context 'approached by similar motion' do
      let(:counterpoint_pitches) { %w[C5 G C5] }
      let(:cantus_firmus_pitches) { %w[C E F] }

      its(:fitness) { is_expected.to eq HeadMusic::PENALTY_FACTOR }
    end

    context 'approached by parallel motion' do
      let(:counterpoint_pitches) { %w[C5 A B] }
      let(:cantus_firmus_pitches) { %w[C D E] }

      its(:fitness) { is_expected.to be <= HeadMusic::PENALTY_FACTOR }
    end

    context 'approached by oblique motion' do
      let(:counterpoint_pitches) { %w[C5 B B] }
      let(:cantus_firmus_pitches) { %w[C D E] }

      it { is_expected.to be_adherent }
    end
  end
end
