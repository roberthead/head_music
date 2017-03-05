require 'spec_helper'

describe HeadMusic::Style::Rules::CantusFirmus do
  let(:composition) { Composition.new(name: 'Majestic D', key_signature: 'D dorian') }
  let(:voice) { Voice.new(composition: composition, role: 'Cantus firmus') }
  let(:rule) { described_class }
  subject(:analysis) { HeadMusic::Style::Analysis.new(rule, voice) }

  context 'with Fuxian examples' do
    [
      { key: 'D dorian', pitches: %w[D4 F4 E4 D4 G4 F4 A4 G4 F4 E4 D4] },
      { key: 'E phrygian', pitches: %w[E4 C4 D4 C4 A3 A4 G4 E4 F4 E4] },
      { key: 'F lydian', pitches: %w[F4 G4 A4 F4 D4 E4 F4 C5 A4 F4 G4 F4] },
    ].each do |fux_example|
      context "#{fux_example[:pitches].join(' ')} in #{fux_example[:key]}" do
        let(:composition) { Composition.new(name: "CF in #{fux_example[:key]}", key_signature: fux_example[:key]) }
        let(:voice) do
          Voice.new(composition: composition).tap do |voice|
            fux_example[:pitches].each_with_index do |pitch, bar|
              voice.place("#{bar + 1}:1", :whole, pitch)
            end
          end
        end

        its(:score) { is_expected.to eq 1 }
      end
    end
  end

  context 'with more than 13 notes' do
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
  end

  context 'with fewer than 8 notes' do
    before do
      %w[D4 E4 F4 G4 F4 E4 D4].each_with_index do |pitch, bar|
        voice.place("#{bar + 1}:1", :whole, pitch)
      end
      expect(voice.notes.length).to eq 7
    end

    its(:score) { is_expected.to be < 1 }
    its(:score) { is_expected.to be > 0 }

    it 'is annotated' do
      expect(analysis.annotations.length).to eq 1
    end
  end

  context 'with a rest in the line' do
    before do
      ["D4", "E4", "F4", "G4", "A4", "B4", "G4", nil, "A4", "G4", "F4", "E4", "D4"].each_with_index do |pitch, bar|
        voice.place("#{bar + 1}:1", :whole, pitch)
      end
    end

    its(:score) { is_expected.to be < 1 }

    it 'is annotated' do
      expect(analysis.annotations.length).to eq 1
    end
  end
end
