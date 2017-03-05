require 'spec_helper'

describe HeadMusic::Style::Rules::UpToThirteenNotes do
  let(:composition) { Composition.new(name: 'Majestic D', key_signature: 'D dorian') }
  let(:voice) { Voice.new(composition: composition, role: 'Cantus firmus') }
  let(:rule) { described_class }
  subject(:analysis) { HeadMusic::Style::Analysis.new(rule, voice) }

  context 'when exactly 13 notes' do
    before do
      %w[D4 E4 F4 G4 A4 B4 G4 B4 A4 G4 F4 E4 D4].each_with_index do |pitch, bar|
        voice.place("#{bar + 1}:1", :whole, pitch)
      end
      expect(voice.notes.length).to eq 13
    end

    its(:score) { is_expected.to eq 1 }
    its(:annotations) { are_expected.to eq [] }
  end

  context 'when more than 13 notes' do
    before do
      %w[D4 E4 F4 G4 A4 B4 G4 A4 G4 F4 E4 D4 C4 E4 D4].each_with_index do |pitch, bar|
        voice.place("#{bar + 1}:1", :whole, pitch)
      end
      expect(voice.notes.length).to eq 15
    end

    its(:score) { is_expected.to be < 1 }
    its(:score) { is_expected.to be > 0 }

    it 'is annotated' do
      expect(analysis.annotations.length).to eq 1
    end

    describe 'annotation' do
      subject(:annotation) { analysis.annotations.first }

      its(:range_string) { is_expected.to eq "14:1:000 to 16:1:000" }

      it 'has a message' do
        expect(annotation.message.length).to be > 8
      end
    end
  end
end
