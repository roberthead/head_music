# frozen_string_literal: true

require 'spec_helper'

describe HeadMusic::Style::Annotations::AvoidCrossingVoices do
  let(:composition) { Composition.new(key_signature: 'D dorian') }
  let(:cantus_firmus) { composition.add_voice(role: :cantus_firmus) }
  let(:counterpoint) { composition.add_voice(role: :counterpoint) }
  subject { described_class.new(counterpoint) }

  its(:message) { is_expected.not_to be_empty }

  context 'when the counterpoint is the high voice' do
    before do
      cantus_firmus_pitches.each.with_index(1) do |pitch, bar|
        cantus_firmus.place("#{bar}:1", :whole, pitch)
      end
      counterpoint_pitches.each.with_index(1) do |pitch, bar|
        counterpoint.place("#{bar}:1", :whole, pitch)
      end
    end

    context 'and the voices do not cross or overlap' do
      let(:cantus_firmus_pitches) { %w[C D E F G F E D C] }
      let(:counterpoint_pitches) { %w[C5 B G A B A G B C5] }

      it { is_expected.to be_adherent }
    end

    context 'and the voices cross' do
      let(:cantus_firmus_pitches) { %w[C D E D G F E D C] }
      let(:counterpoint_pitches) { %w[C5 B G F E A G B C5] }

      its(:fitness) { is_expected.to be < 1 }
    end
  end
end
