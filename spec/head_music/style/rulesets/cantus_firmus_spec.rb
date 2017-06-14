require 'spec_helper'

describe HeadMusic::Style::Rulesets::CantusFirmus do
  FUX_EXAMPLES = [
    { key: 'D dorian', pitches: %w[D F E D G F A G F E D] },
    { key: 'E phrygian', pitches: %w[E C D C A3 A G E F E] },
    { key: 'F lydian', pitches: %w[F G A F D E F C5 A F G F] },
    { key: 'G mixolydian', pitches: %w[G3 C B3 G3 C E D G E C D B3 A3 G3] },
    { key: 'A aeolian', pitches: %w[A3 C B3 D C E F E D C B3 A3] },
    { key: 'C ionian', pitches: %w[C E F G E A G E F E D C] },
    { key: 'C ionian', pitches: %w[C E F E G F E D C] },
  ]

  context 'when given an error-free counterpoint line' do
    let(:composition) { Composition.new(key_signature: 'D dorian') }
    let(:cantus_firmus_pitches) { %w[D F E D G F A G F E D] }
    let!(:cantus_firmus) do
      composition.add_voice(role: :cantus_firmus).tap do |cantus_firmus|
        cantus_firmus_pitches.each.with_index(1) do |pitch, bar|
          value = bar == cantus_firmus_pitches.length ? :breve : :whole
          cantus_firmus.place("#{bar}:1", :whole, pitch)
        end
      end
    end
    subject(:analysis) { HeadMusic::Style::Analysis.new(described_class, cantus_firmus) }

    specify { expect(described_class::RULESET).to include HeadMusic::Style::Annotations::AlwaysMove }
    specify { expect(described_class::RULESET).to include HeadMusic::Style::Annotations::AtLeastEightNotes }
    specify { expect(described_class::RULESET).to include HeadMusic::Style::Annotations::ConsonantClimax }
    specify { expect(described_class::RULESET).to include HeadMusic::Style::Annotations::Diatonic }
    specify { expect(described_class::RULESET).to include HeadMusic::Style::Annotations::DirectionChanges }
    specify { expect(described_class::RULESET).to include HeadMusic::Style::Annotations::EndOnTonic }
    specify { expect(described_class::RULESET).to include HeadMusic::Style::Annotations::LimitOctaveLeaps }
    specify { expect(described_class::RULESET).to include HeadMusic::Style::Annotations::MostlyConjunct }
    specify { expect(described_class::RULESET).to include HeadMusic::Style::Annotations::NoRests }
    specify { expect(described_class::RULESET).to include HeadMusic::Style::Annotations::NotesSameLength }
    specify { expect(described_class::RULESET).to include HeadMusic::Style::Annotations::RecoverLargeLeaps }
    specify { expect(described_class::RULESET).to include HeadMusic::Style::Annotations::SingableIntervals }
    specify { expect(described_class::RULESET).to include HeadMusic::Style::Annotations::SingableRange }
    specify { expect(described_class::RULESET).to include HeadMusic::Style::Annotations::StartOnTonic }
    specify { expect(described_class::RULESET).to include HeadMusic::Style::Annotations::StepDownToFinalNote }
    specify { expect(described_class::RULESET).to include HeadMusic::Style::Annotations::UpToFourteenNotes }

    its(:fitness) { is_expected.to eq 1 }
    its(:messages) { are_expected.to eq [] }
  end

  context 'with Fuxian examples' do
    subject(:analysis) { HeadMusic::Style::Analysis.new(described_class, voice) }

    FUX_EXAMPLES.each do |fux_example|
      context "#{fux_example[:pitches].join(' ')} in #{fux_example[:key]}" do
        let(:composition) { Composition.new(name: "CF in #{fux_example[:key]}", key_signature: fux_example[:key]) }
        let(:voice) { Voice.new(composition: composition) }
        before do
          fux_example[:pitches].each.with_index(1) do |pitch, bar|
            voice.place("#{bar}:1", :whole, pitch)
          end
        end

        its(:fitness) { is_expected.to eq 1 }
        its(:messages) { are_expected.to eq [] }
      end
    end
  end
end
