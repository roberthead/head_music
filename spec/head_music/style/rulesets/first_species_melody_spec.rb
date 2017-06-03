require 'spec_helper'

describe HeadMusic::Style::Rulesets::FirstSpeciesMelody do
  let(:composition) { Composition.new(key_signature: 'D dorian') }
  let(:cantus_firmus) do
    Voice.new(composition: composition, role: 'Cantus Firmus').tap do |voice|
      %w[D4 F4 E4 D4 G4 F4 A4 G4 F4 E4 D4].each_with_index do |pitch, bar|
        voice.place("#{bar + 1}:1", :whole, pitch)
      end
    end
  end
  subject(:analysis) { HeadMusic::Style::Analysis.new(described_class, counterpoint) }

  specify { expect(described_class::RULESET).to include HeadMusic::Style::Annotations::OneToOne }

  specify { expect(described_class::RULESET).to include HeadMusic::Style::Annotations::NotesSameLength }
  specify { expect(described_class::RULESET).to include HeadMusic::Style::Annotations::SingableIntervals }
  specify { expect(described_class::RULESET).to include HeadMusic::Style::Annotations::StartOnPerfectConsonance }
  specify { expect(described_class::RULESET).to include HeadMusic::Style::Annotations::EndOnPerfectConsonance }
  # specify { expect(described_class::RULESET).to include HeadMusic::Style::Annotations::StepUpToFinalNote }
  # specify { expect(described_class::RULESET).to include HeadMusic::Style::Annotations::EndOnPerfectConsonance }

  context 'when given an error-free counterpoint line' do
    let(:counterpoint) do
      Voice.new(composition: composition, role: 'Counterpoint').tap do |voice|
        %w[D5 A4 C5 A4 B4 D5 C5 B4 A4 C5 D5].each_with_index do |pitch, bar|
          voice.place("#{bar + 1}:1", :whole, pitch)
        end
      end
    end

    its(:fitness) { is_expected.to eq 1 }
  end
end
