require 'spec_helper'

describe HeadMusic::Style::Annotations::AlwaysMove do
  let(:voice) { Voice.new }
  subject { described_class.new(voice) }

  its(:message) { is_expected.to eq 'Always move to a different note.' }

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
      %w[C D E D C G3 A3 D C].each.with_index(1) do |pitch, bar|
        voice.place("#{bar}:1", :whole, pitch)
      end
    end

    its(:fitness) { is_expected.to eq 1 }
  end

  context 'with a repeated note' do
    before do
      %w[C D E E C G3 A3 D C].each.with_index(1) do |pitch, bar|
        voice.place("#{bar}:1", :whole, pitch)
      end
    end

    its(:fitness) { is_expected.to eq HeadMusic::PENALTY_FACTOR }
    its(:message) { is_expected.not_to be_empty }
    its(:marks_count) { is_expected.to eq 1 }
    its(:first_mark_code) { is_expected.to eq "3:1:000 to 5:1:000" }
  end
end
