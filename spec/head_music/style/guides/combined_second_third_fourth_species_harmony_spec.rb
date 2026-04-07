require "spec_helper"

describe HeadMusic::Style::Guides::CombinedSecondThirdFourthSpeciesHarmony do
  subject(:analysis) { HeadMusic::Style::Analysis.new(described_class, voice) }

  specify { expect(described_class::RULESET).to include HeadMusic::Style::Guidelines::ApproachPerfectionContrarily }
  specify { expect(described_class::RULESET).to include HeadMusic::Style::Guidelines::AvoidCrossingVoices }
  specify { expect(described_class::RULESET).to include HeadMusic::Style::Guidelines::AvoidOverlappingVoices }
  specify { expect(described_class::RULESET).to include HeadMusic::Style::Guidelines::ConsonantDownbeats }
  specify { expect(described_class::RULESET).to include HeadMusic::Style::Guidelines::NoParallelPerfectOnDownbeats }
  specify { expect(described_class::RULESET).to include HeadMusic::Style::Guidelines::NoParallelPerfectWithSyncopation }
  specify { expect(described_class::RULESET).to include HeadMusic::Style::Guidelines::PreferContraryMotion }
  specify { expect(described_class::RULESET).to include HeadMusic::Style::Guidelines::PreferImperfect }
  specify { expect(described_class::RULESET).to include HeadMusic::Style::Guidelines::FloridDissonanceTreatment }
  specify { expect(described_class::RULESET).to include HeadMusic::Style::Guidelines::SuspensionTreatment }

  context "with a well-formed combined 2+3+4 species counterpoint" do
    let(:composition) { HeadMusic::Content::Composition.new(key_signature: "D dorian", meter: "4/4") }
    let(:voice) { composition.add_voice(role: :counterpoint) }

    before do
      composition.add_voice(role: "cantus firmus").tap do |cantus|
        %w[D4 F4 E4 D4 G4 F4 A4 G4 F4 E4 D4].each.with_index(1) do |pitch, bar|
          cantus.place("#{bar}:1", :whole, pitch)
        end
      end

      voice.place("1:1", :whole, "A4")
      voice.place("2:1", :half, "A4")
      voice.place("2:3", :half, "B4")
      voice.place("3:1", :whole, "C5")
      voice.place("4:1", :half, "A4")
      voice.place("4:3", :half, "B4")
      voice.place("5:1", :quarter, "B4")
      voice.place("5:2", :quarter, "C5")
      voice.place("5:3", :quarter, "B4")
      voice.place("5:4", :quarter, "C5")
      voice.place("6:1", :whole, "D5")
      voice.place("7:1", :half, "C5")
      voice.place("7:3", :half, "E5")
      voice.place("8:1", :whole, "B4")
      voice.place("9:1", :half, "A4")
      voice.place("9:3", :half, "C5")
      voice.place("10:1", :half, "B4")
      voice.place("10:3", :half, "C#5")
      voice.place("11:1", :whole, "D5")
    end

    its(:fitness) { is_expected.to be > 0.5 }
  end
end
