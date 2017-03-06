require 'spec_helper'

describe HeadMusic::Style::Rules::AlwaysMove do
  let(:voice) { Voice.new }
  let(:rule) { described_class }
  subject(:analysis) { HeadMusic::Style::Analysis.new(rule, voice) }

  context 'with no notes' do
    its(:fitness) { is_expected.to eq 1 }
  end

  context 'with one note' do
    before do
      voice.place("1:1", :whole, 'C')
    end

    its(:fitness) { is_expected.to eq 1 }
  end

  context 'with motion' do
    before do
      voice.place("1:1", :whole, 'C')
      voice.place("2:1", :whole, 'D')
      voice.place("3:1", :whole, 'E')
      voice.place("4:1", :whole, 'D')
      voice.place("5:1", :whole, 'C')
      voice.place("6:1", :whole, 'G3')
      voice.place("7:1", :whole, 'A3')
      voice.place("8:1", :whole, 'D')
      voice.place("9:1", :breve, 'C')
    end

    its(:fitness) { is_expected.to eq 1 }
  end

  context 'with a repeated note' do
    before do
      voice.place("1:1", :whole, 'C')
      voice.place("2:1", :whole, 'D')
      voice.place("3:1", :whole, 'E')
      voice.place("4:1", :whole, 'E')
      voice.place("5:1", :whole, 'C')
      voice.place("6:1", :whole, 'G3')
      voice.place("7:1", :whole, 'A3')
      voice.place("8:1", :whole, 'D')
      voice.place("9:1", :breve, 'C')
    end

    its(:fitness) { is_expected.to eq HeadMusic::GOLDEN_RATIO_INVERSE }

    it 'is annotated' do
      expect(analysis.annotations.length).to eq 1
    end

    describe 'annotation' do
      subject(:annotation) { analysis.annotations.first }

      its(:range_string) { is_expected.to eq "3:1:000 to 5:1:000" }

      it 'has a message' do
        expect(annotation.message.length).to be > 8
      end
    end
  end
end
