require "spec_helper"

describe HeadMusic::Style::Guides::TripleMeterMelody do
  subject(:analysis) { HeadMusic::Style::Analysis.new(described_class, voice) }

  specify { expect(described_class::RULESET).to include HeadMusic::Style::Guidelines::AlwaysMove }
  specify { expect(described_class::RULESET).to include HeadMusic::Style::Guidelines::ConsonantClimax }
  specify { expect(described_class::RULESET).to include HeadMusic::Style::Guidelines::Diatonic }
  specify { expect(described_class::RULESET).to include HeadMusic::Style::Guidelines::EndOnTonic }
  specify { expect(described_class::RULESET).to include HeadMusic::Style::Guidelines::FrequentDirectionChanges }
  specify { expect(described_class::RULESET).to include HeadMusic::Style::Guidelines::LimitOctaveLeaps }
  specify { expect(described_class::RULESET).to include HeadMusic::Style::Guidelines::MostlyConjunct }
  specify { expect(described_class::RULESET).to include HeadMusic::Style::Guidelines::PrepareOctaveLeaps }
  specify { expect(described_class::RULESET).to include HeadMusic::Style::Guidelines::SingableIntervals }
  specify { expect(described_class::RULESET).to include HeadMusic::Style::Guidelines::SingableRange }
  specify { expect(described_class::RULESET).to include HeadMusic::Style::Guidelines::StartOnPerfectConsonance }
  specify { expect(described_class::RULESET).to include HeadMusic::Style::Guidelines::StepOutOfUnison }
  specify { expect(described_class::RULESET).to include HeadMusic::Style::Guidelines::StepUpToFinalNote }
  specify { expect(described_class::RULESET).to include HeadMusic::Style::Guidelines::ThreeToOne }

  context "with a well-formed triple-meter counterpoint" do
    let(:composition) { HeadMusic::Content::Composition.new(key_signature: "D dorian", meter: "3/4") }
    let(:voice) { composition.add_voice(role: :counterpoint) }

    before do
      composition.add_voice(role: "cantus firmus").tap do |cantus|
        %w[D4 F4 E4 D4 G4 F4 A4 G4 F4 E4 D4].each.with_index(1) do |pitch, bar|
          cantus.place("#{bar}:1", :dotted_half, pitch)
        end
      end

      # Counterpoint above the CF with three quarter notes per bar
      # Designed to maximize contrary motion and avoid parallel perfect intervals
      quarter_notes = %w[A4 B4 A4 A4 C5 A4 C5 B4 C5 B4 A4 B4 B4 D5 B4 A4 C5 A4 C5 E5 C5 D5 C5 B4 A4 C5 A4 C5 B4 C#5]
      quarter_notes.each_with_index do |pitch, index|
        bar = index / 3 + 1
        beat = index % 3 + 1
        voice.place("#{bar}:#{beat}", :quarter, pitch)
      end
      voice.place("11:1", :dotted_half, "D5")
    end

    its(:fitness) { is_expected.to be > 0.8 }
  end
end
