require 'spec_helper'

describe HeadMusic::Style::Rules::MostlyConjunct do
  let(:composition) { Composition.new }
  let(:voice) { Voice.new(composition: composition) }
  let(:rule) { described_class }
  subject(:annotation) { rule.analyze(voice) }

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
      %w[C D E F G A B C5].each_with_index do |pitch, bar|
        voice.place("#{bar + 1}:1", :whole, pitch)
      end
    end

    its(:fitness) { is_expected.to eq 1 }
  end

  context 'with mostly skips and leaps' do
    before do
      %w[C4 E4 G4 F4 A4 C5 B4 G4 D4 C4].each_with_index do |pitch, bar|
        voice.place("#{bar + 1}:1", :whole, pitch)
      end
    end

    its(:fitness) { is_expected.to be < 1 }
    its(:fitness) { is_expected.to be > 0 }
  end
end
