require "spec_helper"

FUX_FIRST_SPECIES_HARMONY_EXAMPLES = [
  {
    source: "Fux chapter one figure 5",
    key: "D dorian",
    cantus_firmus_pitches: %w[D4 F4 E4 D4 G4 F4 A4 G4 F4 E4 D4],
    counterpoint_pitches: %w[A A G A B C5 C5 B D5 C#5 D5]
  },
  {
    source: "fux chapter one figure 6 (with errors)",
    key: "D dorian",
    cantus_firmus_pitches: %w[D4 F4 E4 D4 G4 F4 A4 G4 F4 E4 D4],
    counterpoint_pitches: %w[G3 D A3 F3 E3 D3 F3 C D C# D],
    expected_message: "Approach perfect consonances by contrary motion."
  },
  {
    source: "fux chapter one figure 6 (corrected)",
    key: "D dorian",
    cantus_firmus_pitches: %w[D4 F4 E4 D4 G4 F4 A4 G4 F4 E4 D4],
    counterpoint_pitches: %w[D3 D3 A3 F3 E3 D3 F3 C D C# D]
  },
  {
    source: "fux chapter one figure 11",
    key: "E phrygian",
    cantus_firmus_pitches: %w[E C D C A3 A4 G E F E],
    counterpoint_pitches: %w[B C5 F G A C5 B E5 D5 E5]
  },
  {
    source: "fux chapter one figure 12 (with melodic errors)",
    key: "E phrygian",
    cantus_firmus_pitches: %w[E C D C A3 A4 G E F E],
    counterpoint_pitches: %w[E3 A3 D3 E3 F3 F3 B3 C4 D4 E4]
  },
  {
    source: "fux chapter one figure 12 (corrected)",
    key: "E phrygian",
    cantus_firmus_pitches: %w[E C D C A3 A4 G E F E],
    counterpoint_pitches: %w[E3 A3 D3 E3 F3 F3 C4 C4 D4 E4]
  },
  {
    source: "fux chapter one figure 13",
    key: "F lydian",
    counterpoint_pitches: %w[F E C F F G A G C F E F],
    cantus_firmus_pitches: %w[F3 G3 A3 F3 D3 E3 F3 C4 A3 F3 G3 F3]
  },
  {
    source: "fux chapter one figure 14",
    key: "F ionian",
    cantus_firmus_pitches: %w[F3 G3 A3 F3 D3 E3 F3 C4 A3 F3 G3 F3],
    counterpoint_pitches: %w[F3 E3 F3 A3 Bb3 G3 A3 E3 F3 D3 E3 F3],
    expected_message: "Avoid crossing voices. Maintain the high-low relationship between voices."
  },
  {
    source: "fux chapter one figure 15 (with melodic errors)",
    key: "G mixolydian",
    counterpoint_pitches: %w[G4 E4 D4 G4 G4 G4 A4 B4 G4 E5 D5 G4 F#4 G4],
    cantus_firmus_pitches: %w[G3 C4 B3 G3 C4 E4 D4 G4 E4 C4 D4 B3 A3 G3]
  },
  {
    source: "fux chapter one figure 15 (corrected)",
    key: "G mixolydian",
    counterpoint_pitches: %w[G4 E4 D4 G4 G4 G4 A4 B4 G4 C5 A4 G4 F#4 G4],
    cantus_firmus_pitches: %w[G3 C4 B3 G3 C4 E4 D4 G4 E4 C4 D4 B3 A3 G3]
  },
  {
    source: "Fux chapter one figure 21",
    key: "G ionian",
    cantus_firmus_pitches: %w[G3 C4 B3 G3 C4 E4 D4 G4 E4 C4 D4 B3 A3 G3],
    counterpoint_pitches: %w[G3 A3 G3 E3 E3 C3 G3 B3 C4 A3 F#3 G3 F#3 G3],
    expected_message:
      "Avoid overlapping voices. Maintain the high-low relationship between voices even for adjacent notes."
  },
  {
    source: "Fux chapter one figure 22",
    key: "A aeolian",
    counterpoint_pitches: %w[A4 E4 G4 F4 E4 C5 A4 B4 B4 A4 G#4 A4],
    cantus_firmus_pitches: %w[A3 C4 B3 D4 C4 E4 F4 E4 D4 C4 B3 A3]
  },
  {
    source: "Fux chapter one figure 23",
    key: "A aeolian",
    cantus_firmus_pitches: %w[A3 C4 B3 D4 C4 E4 F4 E4 D4 C4 B3 A3],
    counterpoint_pitches: %w[A3 A3 G3 F3 E3 E3 D3 C3 G3 A3 G#3 A3]
  }
].freeze

def fux_first_species_harmony_examples
  FUX_FIRST_SPECIES_HARMONY_EXAMPLES.map { |params| CompositionContext.from_params(params) }
end

describe HeadMusic::Style::Guides::FirstSpeciesHarmony do
  subject(:analysis) { HeadMusic::Style::GuideAssessment.new(described_class, voice) }

  specify { expect(guidelines_of(described_class)).to include HeadMusic::Style::Guidelines::ApproachPerfectionContrarily }
  specify { expect(guidelines_of(described_class)).to include HeadMusic::Style::Guidelines::AvoidCrossingVoices }
  specify { expect(guidelines_of(described_class)).to include HeadMusic::Style::Guidelines::AvoidOverlappingVoices }
  specify { expect(guidelines_of(described_class)).to include HeadMusic::Style::Guidelines::ConsonantDownbeats }
  specify { expect(guidelines_of(described_class)).to include HeadMusic::Style::Guidelines::PreferContraryMotion }
  specify { expect(guidelines_of(described_class)).to include HeadMusic::Style::Guidelines::PreferImperfect }
  specify { expect(guidelines_of(described_class)).to include HeadMusic::Style::Guidelines::NoUnisonsInMiddle }
  specify { expect(guidelines_of(described_class)).to include HeadMusic::Style::Guidelines::OneToOne }
  specify { expect(guidelines_of(described_class)).to include HeadMusic::Style::Guidelines::NoParallelPerfectOnDownbeats }

  # The prohibition on consecutive perfect consonances is inherited craft in the
  # other six harmony guides and a taught rule here, because first species has no
  # dissonance treatment to teach and note-against-note consonance handling is
  # what it is for. Registered in SpeciesHarmony::HARMONIC_CRAFT_PROMOTIONS and
  # held to one guide by base_spec.
  #
  # No companion "and not background" example: declaring an item in two tiers
  # raises at require time, so that case is unreachable.
  describe "the taught rules" do
    it "weighs the parallel-perfect prohibition as one" do
      expect(described_class.primary_items.map(&:guideline))
        .to include HeadMusic::Style::Guidelines::NoParallelPerfectOnDownbeats
    end
  end

  # The line this promotion exists for: the cantus firmus of Fux chapter one
  # figure 5 sung again an octave above itself. It is not a counterpoint at all,
  # and before the promotion it graded 0.8300 -- a B -- because it satisfies
  # both of the structural primaries perfectly.
  describe "a line doubled at the octave" do
    let(:voice) { doubled_octave_examples[0].composition.counterpoint_voice }

    # Two expectations, because neither is enough alone.
    #
    # The ceiling is derived: with three equally strong primaries the
    # prohibition owns phi^-1 / 3 = 0.206011 of the rubric, and this line scores
    # 0.008131 on it, so the grade cannot exceed 0.795664 however perfect the
    # rest is. That is the promotion's arithmetic, independent of this fixture.
    #
    # The landing is where it actually falls, well under that ceiling, because
    # it also fails three background items. The ceiling alone does not produce
    # the number, and the number alone is a goalpost someone can quietly move.
    its(:fitness) { is_expected.to be < 0.795664 }
    its(:fitness) { is_expected.to be_within(1e-9).of(0.667415749251) }

    # How the two items that mark this line differ in what they say about it,
    # which is the finding a follow-up story starts from. Ten consecutive
    # perfect octaves earn ten marks from the prohibition and exactly one from
    # the preference, so the preference forgoes 0.381966 * 0.038197 = 0.014590
    # of the grade -- 4.4% of the 0.332584 deficit. Changing how PreferImperfect
    # marks is worth at most that much.
    def item_assessment(guideline)
      analysis.guide_item_assessments.find { |item| item.guide_item.guideline == guideline }
    end

    it "marks every consecutive perfect octave" do
      assessment = item_assessment(HeadMusic::Style::Guidelines::NoParallelPerfectOnDownbeats)

      expect(assessment.marks.length).to eq 10
    end

    it "marks the absence of imperfect consonances only once" do
      assessment = item_assessment(HeadMusic::Style::Guidelines::PreferImperfect)

      expect(assessment.marks.length).to eq 1
      expect(assessment.fitness).to be_within(1e-9).of(HeadMusic::GOLDEN_RATIO_INVERSE)
    end
  end

  # The promotion sharpens rather than depresses: the published line it is
  # measured against is untouched by it.
  describe "Fux chapter one figure 5 as published" do
    let(:voice) { fux_first_species_examples[0].composition.counterpoint_voice }

    its(:fitness) { is_expected.to eq 1.0 }
  end

  context "with Fux examples" do
    fux_first_species_harmony_examples.each do |example|
      context example.description do
        let(:voice) { example.composition.counterpoint_voice }

        if example.expected_messages.any?
          it { is_expected.not_to be_adherent }

          example.expected_messages.each do |expected_message|
            its(:messages) { are_expected.to include(expected_message) }
          end
        else
          it { is_expected.to be_adherent }
        end
      end
    end
  end

  context "with Clendinning examples" do
    clendinning_first_species_examples.each do |example|
      context example.description do
        let(:voice) { example.composition.counterpoint_voice }

        if example.expected_messages.any?
          it { is_expected.not_to be_adherent }

          example.expected_messages.each do |expected_message|
            its(:messages) { are_expected.to include(expected_message) }
          end
        else
          it { is_expected.to be_adherent }
        end
      end
    end
  end

  context "with Davis and Lybbert examples" do
    davis_and_lybbert_first_species_examples.each do |example|
      context example.description do
        let(:voice) { example.composition.counterpoint_voice }

        if example.expected_messages.any?
          it { is_expected.not_to be_adherent }

          example.expected_messages.each do |expected_message|
            its(:messages) { are_expected.to include(expected_message) }
          end
        else
          it { is_expected.to be_adherent }
        end
      end
    end
  end
end
