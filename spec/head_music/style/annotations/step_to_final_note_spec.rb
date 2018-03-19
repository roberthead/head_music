# frozen_string_literal: true

require 'spec_helper'

describe HeadMusic::Style::Guidelines::StepToFinalNote do
  let(:voice) { HeadMusic::Voice.new }
  subject { described_class.new(voice) }

  context 'with no notes' do
    it { is_expected.to be_adherent }
  end

  context 'with one note' do
    before do
      voice.place('1:1', :whole, 'C')
    end

    it { is_expected.to be_adherent }
  end

  context 'when the last melodic interval is a descending step' do
    before do
      voice.place('1:1', :whole, 'C')
      voice.place('2:1', :whole, 'D')
      voice.place('3:1', :whole, 'C')
    end

    it { is_expected.to be_adherent }
  end

  context 'when the last melodic interval is an ascending step' do
    before do
      voice.place('1:1', :whole, 'C4')
      voice.place('2:1', :whole, 'B3')
      voice.place('3:1', :whole, 'C4')
    end

    it { is_expected.to be_adherent }
  end

  context 'when the last melodic interval is a larger descending interval' do
    before do
      voice.place('1:1', :whole, 'C')
      voice.place('2:1', :whole, 'D')
      voice.place('3:1', :whole, 'E')
      voice.place('4:1', :whole, 'C')
    end

    its(:fitness) { is_expected.to eq HeadMusic::PENALTY_FACTOR }
  end

  context 'when the last melodic interval is a larger ascending interval' do
    before do
      voice.place('1:1', :whole, 'C4')
      voice.place('2:1', :whole, 'B3')
      voice.place('3:1', :whole, 'A3')
      voice.place('4:1', :whole, 'C4')
    end

    its(:fitness) { is_expected.to eq HeadMusic::PENALTY_FACTOR }
  end
end
