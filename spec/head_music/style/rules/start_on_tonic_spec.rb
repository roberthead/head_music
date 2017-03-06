require 'spec_helper'

describe HeadMusic::Style::Rules::StartOnTonic do
  let(:composition) { Composition.new(name: "CF in C") }
  let(:voice) { Voice.new(composition: composition) }
  let(:rule) { described_class }
  subject(:analysis) { HeadMusic::Style::Analysis.new(rule, voice) }

  context 'with no notes' do
    its(:fitness) { is_expected.to eq 0 }
  end

  context 'when the first note is the tonic' do
    before do
      voice.place("1:1", :whole, 'C')
    end

    its(:fitness) { is_expected.to eq 1 }
  end

  context 'when the first note is NOT the tonic' do
    before do
      voice.place('1:1', :whole, 'D')
    end

    its(:fitness) { is_expected.to be < 1 }

    it 'is annotated' do
      expect(analysis.annotations.length).to eq 1
    end

    describe 'annotation' do
      subject(:annotation) { analysis.annotations.first }

      its(:range_string) { is_expected.to eq "1:1:000 to 2:1:000" }

      it 'has a message' do
        expect(annotation.message.length).to be > 8
      end
    end
  end
end
