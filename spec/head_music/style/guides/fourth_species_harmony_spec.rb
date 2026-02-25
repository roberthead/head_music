require "spec_helper"

describe HeadMusic::Style::Guides::FourthSpeciesHarmony do
  subject(:analysis) { HeadMusic::Style::Analysis.new(described_class, voice) }

  specify { expect(described_class::RULESET).to include HeadMusic::Style::Guidelines::ApproachPerfectionContrarily }
  specify { expect(described_class::RULESET).to include HeadMusic::Style::Guidelines::AvoidCrossingVoices }
  specify { expect(described_class::RULESET).to include HeadMusic::Style::Guidelines::AvoidOverlappingVoices }
  specify { expect(described_class::RULESET).to include HeadMusic::Style::Guidelines::ConsonantDownbeats }
  specify { expect(described_class::RULESET).to include HeadMusic::Style::Guidelines::NoParallelPerfectOnDownbeats }
  specify { expect(described_class::RULESET).to include HeadMusic::Style::Guidelines::NoParallelPerfectWithSyncopation }
  specify { expect(described_class::RULESET).to include HeadMusic::Style::Guidelines::NoStrongBeatUnisons }
  specify { expect(described_class::RULESET).to include HeadMusic::Style::Guidelines::PreferContraryMotion }
  specify { expect(described_class::RULESET).to include HeadMusic::Style::Guidelines::PreferImperfect }
  specify { expect(described_class::RULESET).to include HeadMusic::Style::Guidelines::SecondSpeciesBreak }
  specify { expect(described_class::RULESET).to include HeadMusic::Style::Guidelines::SuspensionTreatment }

  context "with a well-formed fourth-species counterpoint" do
    let(:composition) { HeadMusic::Content::Composition.new(key_signature: "D dorian") }
    let(:voice) { composition.add_voice(role: :counterpoint) }

    before do
      composition.add_voice(role: "cantus firmus").tap do |cantus|
        %w[D4 F4 E4 D4 G4 F4 A4 G4 F4 E4 D4].each.with_index(1) do |pitch, bar|
          cantus.place("#{bar}:1", :whole, pitch)
        end
      end

      # Fourth species: half notes starting on beat 3, sustaining across barlines
      %w[A4 D5 C5 B4 D5 C5 E5 D5 C5 C#5].each_with_index do |pitch, index|
        voice.place("#{index + 1}:3", :whole, pitch)
      end
      voice.place("11:1", :whole, "D5")
    end

    its(:fitness) { is_expected.to be > 0.5 }
  end
end
