require 'spec_helper'

describe HeadMusic::Style::Annotations::StartOnTonic do
  let(:voice) { Voice.new }
  subject { described_class.new(voice) }

  context 'with no notes' do
    its(:fitness) { is_expected.to eq 1 }
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
    its(:marks_count) { is_expected.to eq 1 }
    its(:first_mark_code) { is_expected.to eq "1:1:000 to 2:1:000" }
    its(:message) { is_expected.not_to be_empty }
  end
end
