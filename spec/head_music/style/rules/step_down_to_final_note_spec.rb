require 'spec_helper'

describe HeadMusic::Style::Rules::StepDownToFinalNote do
  let(:composition) { Composition.new(name: "CF in C") }
  let(:voice) { Voice.new(composition: composition) }
  let(:rule) { described_class }
  subject(:analysis) { HeadMusic::Style::Analysis.new(rule, voice) }

  context 'with no notes' do
    its(:fitness) { is_expected.to eq 0 }
  end

  context 'with one note' do
    before do
      voice.place("1:1", :whole, 'C')
    end

    its(:fitness) { is_expected.to eq 0 }
  end

  context 'when the last melodic interval is a descending step' do
    before do
      voice.place("1:1", :whole, 'C')
      voice.place("2:1", :whole, 'D')
      voice.place("3:1", :whole, 'C')
    end

    its(:fitness) { is_expected.to eq 1 }
  end

  context 'when the last melodic interval is an ascending step' do
    before do
      voice.place("1:1", :whole, 'C4')
      voice.place("2:1", :whole, 'B3')
      voice.place("3:1", :whole, 'C4')
    end

    its(:fitness) { is_expected.to eq GOLDEN_RATIO_INVERSE }
  end

  context 'when the last melodic interval is a larger descending interval' do
    before do
      voice.place("1:1", :whole, 'C')
      voice.place("2:1", :whole, 'D')
      voice.place("3:1", :whole, 'E')
      voice.place("4:1", :whole, 'C')
    end

    its(:fitness) { is_expected.to eq GOLDEN_RATIO_INVERSE }
  end

  context 'when the last melodic interval is a larger ascending interval' do
    before do
      voice.place("1:1", :whole, 'C4')
      voice.place("2:1", :whole, 'B3')
      voice.place("3:1", :whole, 'A3')
      voice.place("4:1", :whole, 'C4')
    end

    its(:fitness) { is_expected.to eq GOLDEN_RATIO_INVERSE**2 }
  end
end
