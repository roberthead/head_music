require 'spec_helper'

describe HeadMusic::Style::Rulesets::CantusFirmus do
  FUX_EXAMPLES = [
    { key: 'D dorian', pitches: %w[D4 F4 E4 D4 G4 F4 A4 G4 F4 E4 D4] },
    { key: 'E phrygian', pitches: %w[E4 C4 D4 C4 A3 A4 G4 E4 F4 E4] },
    { key: 'F lydian', pitches: %w[F4 G4 A4 F4 D4 E4 F4 C5 A4 F4 G4 F4] },
  ]

  context 'when given an error-free counterpoint line' do
    let(:composition) { Composition.new(key_signature: 'D dorian') }
    let(:cantus_firmus_pitches) { %w[D4 F4 E4 D4 G4 F4 A4 G4 F4 E4 D4] }
    let!(:cantus_firmus) do
      composition.add_voice(role: :cantus_firmus).tap do |cantus_firmus|
        cantus_firmus_pitches.each.with_index(1) do |pitch, bar|
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
    specify { expect(described_class::RULESET).to include HeadMusic::Style::Annotations::UpToThirteenNotes }

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

        its(:fitness) { is_expected.to be > PENALTY_FACTOR }
        its(:fitness) { is_expected.to eq 1 }
      end
    end
  end
end
