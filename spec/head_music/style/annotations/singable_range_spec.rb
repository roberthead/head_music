require 'spec_helper'

describe HeadMusic::Style::Annotations::SingableRange do
  let(:voice) { Voice.new }
  subject { described_class.new(voice) }

  context 'when there are no notes' do
    its(:fitness) { is_expected.to eq 1 }
  end

  context 'when the range is small' do
    before do
      %w[D4 E4 F4 A4 G4 F4 G4 E4 D4].each.with_index(1) do |pitch, bar|
        voice.place("#{bar}:1", :whole, pitch)
      end
    end

    its(:fitness) { is_expected.to eq 1 }
    its(:marks_count) { is_expected.to eq 0 }
  end

  context 'when the range is large' do
    before do
      %w[G3 C4 D4 Eb4 C4 G4 Eb4 C5 C4 Eb4 D4 C4 G4 Eb4 C4 G3 G3 C4].each.with_index(1) do |pitch, bar|
        voice.place("#{bar}:1", :whole, pitch)
      end
    end

    its(:fitness) { is_expected.to be < 1 }
    its(:message) { is_expected.not_to be_empty }
    its(:marks_count) { is_expected.to eq 4 }

    it 'marks all instances of the highest and lowest note' do
      bars = [1, 8, 16, 17]
      codes = bars.map { |bar| "#{bar}:1:000 to #{bar+1}:1:000" }
      expect(subject.marks.map(&:code)).to eq codes
    end
  end
end
