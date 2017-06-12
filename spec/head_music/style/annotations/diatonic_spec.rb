require 'spec_helper'

describe HeadMusic::Style::Annotations::Diatonic do
  let(:composition) { Composition.new(key_signature: 'D dorian') }
  let(:voice) { composition.add_voice }
  subject { described_class.new(voice) }

  its(:message) { is_expected.not_to be_empty }

  context 'when there are no notes' do
    its(:fitness) { is_expected.to eq 1 }
    its(:marks_count) { is_expected.to eq 0 }
  end

  context 'when the notes are in the key' do
    before do
      %w[D4 E4 F4 G4 A4 B4 G4 B4 A4 G4 F4 E4 D4].each.with_index(1) do |pitch, bar|
        voice.place("#{bar}:1", :whole, pitch)
      end
    end

    its(:fitness) { is_expected.to eq 1 }
    its(:marks_count) { is_expected.to eq 0 }
  end

  context 'when a note is not in the key' do
    before do
      %w[D4 E4 F#4 G4 A4 B4 G4 B4 A4 G4 F#4 E4 D4].each.with_index(1) do |pitch, bar|
        voice.place("#{bar}:1", :whole, pitch)
      end
    end

    its(:fitness) { is_expected.to be < 1 }
    its(:fitness) { is_expected.to be > 0 }
    its(:marks_count) { is_expected.to eq 2 }
  end

  context 'with a raised leading tone in the cadence' do
    before do
      %w[D E F D B3 C D B3 C D A3 B3 C# D].each.with_index(1) do |pitch, bar|
        voice.place("#{bar}:1", :whole, pitch)
      end
    end

    its(:fitness) { is_expected.to eq 1 }
  end
end
