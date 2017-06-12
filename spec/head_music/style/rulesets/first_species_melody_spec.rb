require 'spec_helper'

describe HeadMusic::Style::Rulesets::FirstSpeciesMelody do
  let(:composition) { Composition.new(key_signature: 'D dorian') }
  let(:cantus_firmus_pitches) { %w[D4 F4 E4 D4 G4 F4 A4 G4 F4 E4 D4] }
  let!(:cantus_firmus) do
    composition.add_voice(role: :cantus_firmus).tap do |cantus_firmus|
      cantus_firmus_pitches.each.with_index(1) do |pitch, bar|
        cantus_firmus.place("#{bar}:1", :whole, pitch)
      end
    end
  end
  subject(:analysis) { HeadMusic::Style::Analysis.new(described_class, counterpoint) }

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
  specify { expect(described_class::RULESET).to include HeadMusic::Style::Annotations::StartOnPerfectConsonance }
  specify { expect(described_class::RULESET).to include HeadMusic::Style::Annotations::StepOutOfUnison }
  specify { expect(described_class::RULESET).to include HeadMusic::Style::Annotations::StepUpToFinalNote }

  context 'when given an error-free counterpoint line' do
    let(:counterpoint) do
      Voice.new(composition: composition, role: 'Counterpoint').tap do |voice|
        %w[A A G A B C5 C5 B D5 C#5 D5].each.with_index(1) do |pitch, bar|
          voice.place("#{bar}:1", :whole, pitch)
        end
      end
    end

    its(:fitness) { is_expected.to eq 1 }
    its(:messages) { are_expected.to eq [] }
  end
end
