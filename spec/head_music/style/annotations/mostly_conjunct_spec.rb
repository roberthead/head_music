require 'spec_helper'

describe HeadMusic::Style::Annotations::MostlyConjunct do
  let(:voice) { Voice.new }
  subject { described_class.new(voice) }

  context 'with no notes' do
    its(:fitness) { is_expected.to eq 1 }
  end

  context 'with one note' do
    before do
      voice.place("1:1", :whole, 'C')
    end

    its(:fitness) { is_expected.to eq 1 }
  end

  context 'with a scale' do
    before do
      %w[C D E F G A B C5].each.with_index(1) do |pitch, bar|
        voice.place("#{bar}:1", :whole, pitch)
      end
    end

    its(:fitness) { is_expected.to eq 1 }
  end

  context 'with half skips and leaps' do
    before do
      %w[C D E G F A C5 B G D C].each.with_index(1) do |pitch, bar|
        voice.place("#{bar}:1", :whole, pitch)
      end
    end

    its(:fitness) { is_expected.to eq 1 }
  end

  context 'with more than half skips and leaps' do
    before do
      %w[C E G F A C5 B G D C].each.with_index(1) do |pitch, bar|
        voice.place("#{bar}:1", :whole, pitch)
      end
    end

    its(:fitness) { is_expected.to be < 1 }
    its(:fitness) { is_expected.to be > 0 }
  end

  context 'with mostly skips and leaps' do
    before do
      %w[C E G B G B G E D C].each.with_index(1) do |pitch, bar|
        voice.place("#{bar}:1", :whole, pitch)
      end
    end

    its(:fitness) { is_expected.to be < 1 }
    its(:fitness) { is_expected.to be > 0 }
  end
end
