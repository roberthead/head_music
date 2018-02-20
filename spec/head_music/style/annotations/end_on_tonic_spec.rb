# frozen_string_literal: true

require 'spec_helper'

describe HeadMusic::Style::Annotations::EndOnTonic do
  let(:voice) { Voice.new }
  subject { described_class.new(voice) }

  context 'with no notes' do
    it { is_expected.to be_adherent }
  end

  context 'when the last note is the tonic' do
    before do
      voice.place('1:1', :whole, 'C')
      voice.place('2:1', :whole, 'D')
      voice.place('3:1', :whole, 'C')
    end

    it { is_expected.to be_adherent }
  end

  context 'when the first note is NOT the tonic' do
    before do
      voice.place('1:1', :whole, 'D')
      voice.place('2:1', :whole, 'E')
      voice.place('3:1', :whole, 'D')
    end

    its(:fitness) { is_expected.to be < 1 }
    its(:marks_count) { is_expected.to eq 1 }
    its(:message) { is_expected.not_to be_empty }
    its(:first_mark_code) { is_expected.to eq '3:1:000 to 4:1:000' }
  end
end
