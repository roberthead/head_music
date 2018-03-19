# frozen_string_literal: true

require 'spec_helper'

describe HeadMusic::Style::Guidelines::UpToFourteenNotes do
  let(:composition) { HeadMusic::Composition.new(key_signature: 'D dorian') }
  let(:voice) { HeadMusic::Voice.new(composition: composition, role: 'Cantus Firmus') }
  subject { described_class.new(voice) }

  context 'when exactly 14 notes' do
    before do
      %w[D E F G A B G B G A G F E D].each.with_index(1) do |pitch, bar|
        voice.place("#{bar}:1", :whole, pitch)
      end
      expect(voice.notes.length).to eq 14
    end

    it { is_expected.to be_adherent }
    its(:marks_count) { is_expected.to eq 0 }
  end

  context 'when more than 14 notes' do
    before do
      %w[D E F G A B G A G F E D C E D].each.with_index(1) do |pitch, bar|
        voice.place("#{bar}:1", :whole, pitch)
      end
      expect(voice.notes.length).to eq 15
    end

    its(:fitness) { is_expected.to be < 1 }
    its(:fitness) { is_expected.to be > 0 }
    its(:marks_count) { is_expected.to eq 1 }
    its(:first_mark_code) { is_expected.to eq '15:1:000 to 16:1:000' }
    its(:message) { is_expected.not_to be_empty }
  end
end
