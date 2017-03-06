require 'spec_helper'

describe HeadMusic::Style::Rules::UpToThirteenNotes do
  let(:composition) { Composition.new(name: 'Majestic D', key_signature: 'D dorian') }
  let(:voice) { Voice.new(composition: composition, role: 'Cantus firmus') }
  let(:rule) { described_class }
  subject(:annotation) { rule.analyze(voice) }

  context 'when exactly 13 notes' do
    before do
      %w[D4 E4 F4 G4 A4 B4 G4 B4 A4 G4 F4 E4 D4].each_with_index do |pitch, bar|
        voice.place("#{bar + 1}:1", :whole, pitch)
      end
      expect(voice.notes.length).to eq 13
    end

    its(:fitness) { is_expected.to eq 1 }
    its(:marks_count) { is_expected.to eq 0 }
  end

  context 'when more than 13 notes' do
    before do
      %w[D4 E4 F4 G4 A4 B4 G4 A4 G4 F4 E4 D4 C4 E4 D4].each_with_index do |pitch, bar|
        voice.place("#{bar + 1}:1", :whole, pitch)
      end
      expect(voice.notes.length).to eq 15
    end

    its(:fitness) { is_expected.to be < 1 }
    its(:fitness) { is_expected.to be > 0 }
    its(:marks_count) { is_expected.to eq 1 }
    its(:first_mark_code) { is_expected.to eq "14:1:000 to 16:1:000" }
    its(:message) { is_expected.not_to be_empty }
  end
end
