require 'spec_helper'

describe HeadMusic::Style::Rules::NoRests do
  let(:voice) { Voice.new }
  let(:rule) { described_class }
  subject(:analysis) { HeadMusic::Style::Analysis.new(rule, voice) }

  context 'when there are no rests' do
    before do
      %w[D4 E4 F4 G4 A4 B4 G4 B4 A4 G4 F4 E4 D4].each_with_index do |pitch, bar|
        voice.place("#{bar + 1}:1", :whole, pitch)
      end
    end

    its(:fitness) { is_expected.to eq 1 }
    its(:annotations) { are_expected.to eq [] }
  end

  context 'when there are rests' do
    before do
      ["D4", "E4", "F4", "G4", "A4", "B4", "G4", nil, "A4", "G4", "F4", "E4", "D4"].each_with_index do |pitch, bar|
        voice.place("#{bar + 1}:1", :whole, pitch)
      end
    end

    its(:fitness) { is_expected.to be < 1 }

    it 'is annotated' do
      expect(analysis.annotations.length).to eq 1
    end

    describe 'annotation' do
      subject(:annotation) { analysis.annotations.first }

      its(:start_position) { is_expected.to eq "8:1" }
      its(:end_position) { is_expected.to eq "9:1" }
      its(:range_string) { is_expected.to eq "8:1:000 to 9:1:000" }

      it 'has a message' do
        expect(annotation.message.length).to be > 8
      end
    end
  end
end
