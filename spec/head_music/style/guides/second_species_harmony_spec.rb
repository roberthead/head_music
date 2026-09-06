require "spec_helper"

describe HeadMusic::Style::Guides::SecondSpeciesHarmony do
  subject(:analysis) { HeadMusic::Style::GuideAssessment.new(described_class, voice) }

  specify { expect(guidelines_of(described_class)).to include HeadMusic::Style::Guidelines::ApproachPerfectionContrarily }
  specify { expect(guidelines_of(described_class)).to include HeadMusic::Style::Guidelines::AvoidCrossingVoices }
  specify { expect(guidelines_of(described_class)).to include HeadMusic::Style::Guidelines::AvoidOverlappingVoices }
  specify { expect(guidelines_of(described_class)).to include HeadMusic::Style::Guidelines::ConsonantDownbeats }
  specify { expect(guidelines_of(described_class)).to include HeadMusic::Style::Guidelines::NoParallelPerfectAcrossBarline }
  specify { expect(guidelines_of(described_class)).to include HeadMusic::Style::Guidelines::NoParallelPerfectOnDownbeats }
  specify { expect(guidelines_of(described_class)).to include HeadMusic::Style::Guidelines::NoStrongBeatUnisons }
  specify { expect(guidelines_of(described_class)).to include HeadMusic::Style::Guidelines::PreferContraryMotion }
  specify { expect(guidelines_of(described_class)).to include HeadMusic::Style::Guidelines::PreferImperfect }
  specify { expect(guidelines_of(described_class)).to include HeadMusic::Style::Guidelines::WeakBeatDissonanceTreatment }

  context "with a well-formed second-species counterpoint" do
    let(:flow) { HeadMusic::Content::Flow.new(key_signature: "D dorian") }
    let(:voice) { flow.add_voice(role: :counterpoint) }

    before do
      flow.add_voice(role: "cantus firmus").tap do |cantus|
        %w[D4 F4 E4 D4 G4 F4 A4 G4 F4 E4 D4].each.with_index(1) do |pitch, bar|
          cantus.place("#{bar}:1", :whole, pitch)
        end
      end

      # Counterpoint above the CF with two half notes per bar
      half_notes = %w[A4 B4 A4 C5 B4 C5 A4 B4 B4 C5 A4 D5 C5 E5 D5 B4 A4 C5 C#5]
      half_notes.each_with_index do |pitch, index|
        bar = index / 2 + 1
        beat = (index % 2) * 2 + 1
        voice.place("#{bar}:#{beat}", :half, pitch)
      end
      voice.place("11:1", :whole, "D5")
    end

    # Two expectations, because neither is enough alone.
    #
    # The ceiling: this counterpoint fails the taught rule --
    # WeakBeatDissonanceTreatment -- at phi^-1, and the taught rule is now the
    # whole primary tier, carrying phi^-1 of the rubric. So the grade cannot
    # exceed phi^-1 * phi^-1 + phi^-2 = 2 * phi^-2 = 0.7639 however well the
    # background is written.
    #
    # The landing: it comes in below that ceiling, at 0.6979, because it also
    # fails three background items -- ApproachPerfectionContrarily and
    # NoParallelPerfectOnDownbeats at phi^-1, NoParallelPerfectAcrossBarline at
    # phi^-2. The ceiling alone does not produce that number, and the number
    # alone is a goalpost someone can quietly move.
    its(:fitness) { is_expected.to be < 2 * HeadMusic::GOLDEN_RATIO_INVERSE**2 }
    its(:fitness) { is_expected.to be_within(0.0005).of(0.6979) }
  end
end
