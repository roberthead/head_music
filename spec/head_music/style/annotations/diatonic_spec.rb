require 'spec_helper'

describe HeadMusic::Style::Annotations::Diatonic do
  let(:composition) { Composition.new(key_signature: 'D dorian') }
  let(:voice) { Voice.new(composition: composition) }
  subject { described_class.new(voice) }

  context 'when there are no notes' do
    its(:fitness) { is_expected.to eq 1 }
    its(:marks_count) { is_expected.to eq 0 }
  end

  context 'when the notes are in the key' do
    before do
      %w[D4 E4 F4 G4 A4 B4 G4 B4 A4 G4 F4 E4 D4].each_with_index do |pitch, bar|
        voice.place("#{bar + 1}:1", :whole, pitch)
      end
    end

    its(:fitness) { is_expected.to eq 1 }
    its(:marks_count) { is_expected.to eq 0 }
  end

  context 'when a note is not in the key' do
    before do
      %w[D4 E4 F#4 G4 A4 B4 G4 B4 A4 G4 F#4 E4 D4].each_with_index do |pitch, bar|
        voice.place("#{bar + 1}:1", :whole, pitch)
      end
    end

    its(:fitness) { is_expected.to be < 1 }
    its(:fitness) { is_expected.to be > 0 }
    its(:marks_count) { is_expected.to eq 2 }
    its(:message) { is_expected.not_to be_empty }
  end
end
