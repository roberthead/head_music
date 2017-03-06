require 'spec_helper'

describe HeadMusic::Style::Rulesets::CantusFirmus do
  FUX_EXAMPLES = [
    { key: 'D dorian', pitches: %w[D4 F4 E4 D4 G4 F4 A4 G4 F4 E4 D4] },
    { key: 'E phrygian', pitches: %w[E4 C4 D4 C4 A3 A4 G4 E4 F4 E4] },
    { key: 'F lydian', pitches: %w[F4 G4 A4 F4 D4 E4 F4 C5 A4 F4 G4 F4] },
  ]

  context 'with Fuxian examples' do
    let(:ruleset) { described_class }
    subject(:analysis) { HeadMusic::Style::Analysis.new(ruleset, voice) }

    FUX_EXAMPLES.each do |fux_example|
      context "#{fux_example[:pitches].join(' ')} in #{fux_example[:key]}" do
        let(:composition) { Composition.new(name: "CF in #{fux_example[:key]}", key_signature: fux_example[:key]) }
        let(:voice) { Voice.new(composition: composition) }
        before do
          fux_example[:pitches].each_with_index do |pitch, bar|
            voice.place("#{bar + 1}:1", :whole, pitch)
          end
        end

        its(:fitness) { is_expected.to eq 1 }
      end
    end
  end

  describe 'when in D dorian' do
    let(:composition) { Composition.new(name: 'Majestic D', key_signature: 'D dorian') }
    let(:voice) { Voice.new(composition: composition, role: 'Cantus firmus') }
    let(:rule) { described_class }
    subject(:analysis) { HeadMusic::Style::Analysis.new(rule, voice) }

    context 'with more than 13 notes' do
      before do
        %w[D4 E4 F4 G4 A4 B4 G4 A4 G4 F4 E4 D4 C4 E4 D4].each_with_index do |pitch, bar|
          voice.place("#{bar + 1}:1", :whole, pitch)
        end
      end

      its(:fitness) { is_expected.to be < 1 }
      its(:fitness) { is_expected.to be > 0 }
    end

    context 'with fewer than 8 notes' do
      before do
        %w[D4 E4 F4 G4 F4 E4 D4].each_with_index do |pitch, bar|
          voice.place("#{bar + 1}:1", :whole, pitch)
        end
      end

      its(:fitness) { is_expected.to be < 1 }
      its(:fitness) { is_expected.to be > 0 }
    end

    context 'with a rest in the line' do
      before do
        ["D4", "E4", "F4", "G4", "A4", "B4", "G4", nil, "A4", "G4", "F4", "E4", "D4"].each_with_index do |pitch, bar|
          voice.place("#{bar + 1}:1", :whole, pitch)
        end
      end

      its(:fitness) { is_expected.to be < 1 }
      its(:fitness) { is_expected.to be > 0 }
    end

    context 'when it does not start on the tonic' do
      before do
        %w[F4 E4 D4 G4 F4 A4 G4 F4 E4 D4].each_with_index do |pitch, bar|
          voice.place("#{bar + 1}:1", :whole, pitch)
        end
      end

      its(:fitness) { is_expected.to be < 1 }
      its(:fitness) { is_expected.to be > 0 }
    end

    context 'when it does not end on the tonic' do
      before do
        %w[D4 F4 E4 D4 G4 F4 A4 G4 F4 E4].each_with_index do |pitch, bar|
          voice.place("#{bar + 1}:1", :whole, pitch)
        end
      end

      its(:fitness) { is_expected.to be < 1 }
      its(:fitness) { is_expected.to be > 0 }
    end

    context 'when it skips to the final note' do
      before do
        %w[D4 F4 E4 D4 G4 F4 A4 G4 F4 D4].each_with_index do |pitch, bar|
          voice.place("#{bar + 1}:1", :whole, pitch)
        end
      end

      its(:fitness) { is_expected.to be < 1 }
      its(:fitness) { is_expected.to be > 0 }
    end

    context 'when notes are not of equal rhythmic value' do
      before do
        voice.place("1:1", :whole, 'D4')
        voice.place("2:1", :half, 'E4')
        voice.place("2:3", :half, 'F4')
        voice.place("3:1", :whole, 'E4')
        voice.place("4:1", :half, 'G4')
        voice.place("4:3", :half, 'F4')
        voice.place("5:1", :whole, 'E4')
        voice.place("6:1", :whole, 'D4')
      end

      its(:fitness) { is_expected.to be < 1 }
      its(:fitness) { is_expected.to be > 0 }
    end

    context 'when a note repeats' do
      before do
        %w[D4 E4 F4 G4 F4 E4 E4 F4 E4 D4].each_with_index do |pitch, bar|
          voice.place("#{bar + 1}:1", :whole, pitch)
        end
      end

      its(:fitness) { is_expected.to be < 1 }
      its(:fitness) { is_expected.to be > 0 }
    end

    context 'when the range is large' do
      before do
        %w[D4 A3 D4 E4 F4 D4 A4 F4 D5 D4].each_with_index do |pitch, bar|
          voice.place("#{bar + 1}:1", :whole, pitch)
        end
      end

      its(:fitness) { is_expected.to be < 1 }
      its(:fitness) { is_expected.to be > 0 }
    end

    context 'when an accidental is used' do
      before do
        %w[D4 F4 E4 D4 G4 F4 A4 G4 F#4 E4 D4].each_with_index do |pitch, bar|
          voice.place("#{bar + 1}:1", :whole, pitch)
        end
      end

      its(:fitness) { is_expected.to be < 1 }
      its(:fitness) { is_expected.to be > 0 }
    end

    context 'when mostly skips and leaps' do
      before do
        %w[D4 F4 D4 G4 E4 A4 G4 F4 E4 D4].each_with_index do |pitch, bar|
          voice.place("#{bar + 1}:1", :whole, pitch)
        end
      end

      its(:fitness) { is_expected.to be < 1 }
      its(:fitness) { is_expected.to be > 0 }
    end
  end
end
