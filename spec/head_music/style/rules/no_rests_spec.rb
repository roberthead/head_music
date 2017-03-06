require 'spec_helper'

describe HeadMusic::Style::Rules::NoRests do
  let(:voice) { Voice.new }
  let(:rule) { described_class }
  subject(:annotation) { rule.analyze(voice) }

  context 'when there are no rests' do
    before do
      %w[D4 E4 F4 G4 A4 B4 G4 B4 A4 G4 F4 E4 D4].each_with_index do |pitch, bar|
        voice.place("#{bar + 1}:1", :whole, pitch)
      end
    end

    its(:fitness) { is_expected.to eq 1 }
    its(:marks_count) { is_expected.to eq 0 }
  end

  context 'when there are rests' do
    before do
      ["D4", "E4", "F4", "G4", "A4", "B4", "G4", nil, "A4", "G4", "F4", "E4", "D4"].each_with_index do |pitch, bar|
        voice.place("#{bar + 1}:1", :whole, pitch)
      end
    end

    its(:fitness) { is_expected.to be < 1 }
    its(:message) { is_expected.not_to be_empty }

    describe 'mark' do
      subject(:mark) { annotation.marks.first }

      its(:code) { is_expected.to eq "8:1:000 to 9:1:000" }
    end
  end
end
