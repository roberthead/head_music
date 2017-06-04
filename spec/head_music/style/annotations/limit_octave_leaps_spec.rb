require 'spec_helper'

describe HeadMusic::Style::Annotations::LimitOctaveLeaps do
  let(:composition) { Composition.new(key_signature: 'C major') }
  let(:voice) { composition.add_voice(role: :counterpoint) }
  subject { described_class.new(voice) }

  context 'with no notes' do
    its(:fitness) { is_expected.to eq 1 }
  end

  context 'with no octave leaps' do
    before do
      %w[C D E G C5 B A B C5].each.with_index(1) do |pitch, bar|
        voice.place("#{bar}:1", :whole, pitch)
      end
    end

    its(:fitness) { is_expected.to eq 1 }
  end

  context 'with one octave leap' do
    before do
      %w[C5 B C5 C D E G B C5].each.with_index(1) do |pitch, bar|
        voice.place("#{bar}:1", :whole, pitch)
      end
    end

    its(:fitness) { is_expected.to eq 1 }
  end

  context 'with two octave leaps' do
    before do
      %w[C5 B C5 C D C C5 B G B C5].each.with_index(1) do |pitch, bar|
        voice.place("#{bar}:1", :whole, pitch)
      end
    end

    its(:fitness) { is_expected.to be <= PENALTY_FACTOR }
  end
end
