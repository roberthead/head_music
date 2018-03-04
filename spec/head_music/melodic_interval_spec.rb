# frozen_string_literal: true

require 'spec_helper'

describe HeadMusic::MelodicInterval do
  let(:voice) { HeadMusic::Voice.new }
  let(:note1) { HeadMusic::Note.new('D4', :quarter, voice, '2:1') }
  let(:note2) { HeadMusic::Note.new('G4', :quarter, voice, '2:3') }
  subject(:melodic_interval) { described_class.new(note1, note2) }

  its(:first_note) { is_expected.to eq note1 }
  its(:second_note) { is_expected.to eq note2 }

  its(:functional_interval) { is_expected.to eq 'perfect fourth' }
  its(:position_start) { is_expected.to eq '2:1' }
  its(:position_end) { is_expected.to eq '2:4' }
  its(:notes) { are_expected.to eq [note1, note2] }
  its(:to_s) { is_expected.to eq 'ascending perfect fourth' }

  it { is_expected.to be_moving }
  it { is_expected.to be_ascending }
  it { is_expected.not_to be_descending }
end
