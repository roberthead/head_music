require 'spec_helper'

describe HeadMusic::Style::Rulesets::FirstSpeciesHarmony do
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

  specify { expect(described_class::RULESET).to include HeadMusic::Style::Annotations::ApproachPerfectionContrarily }
  specify { expect(described_class::RULESET).to include HeadMusic::Style::Annotations::AvoidCrossingVoices }
  specify { expect(described_class::RULESET).to include HeadMusic::Style::Annotations::AvoidOverlappingVoices }
  specify { expect(described_class::RULESET).to include HeadMusic::Style::Annotations::ConsonantDownbeats }
  specify { expect(described_class::RULESET).to include HeadMusic::Style::Annotations::PreferContraryMotion }
  specify { expect(described_class::RULESET).to include HeadMusic::Style::Annotations::NoUnisonsInMiddle }
  specify { expect(described_class::RULESET).to include HeadMusic::Style::Annotations::OneToOne }
  specify { expect(described_class::RULESET).to include HeadMusic::Style::Annotations::AvoidCrossingVoices }

  context 'when given an error-free counterpoint line' do
    let(:counterpoint) do
      Voice.new(composition: composition, role: 'Counterpoint').tap do |voice|
        %w[D5 A4 C5 D5 B4 D5 C5 B4 A4 C5 D5].each.with_index(1) do |pitch, bar|
          voice.place("#{bar}:1", :whole, pitch)
        end
      end
    end

    its(:fitness) { is_expected.to eq 1 }
  end
end
