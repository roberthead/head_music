require "spec_helper"

# A fifth-species exercise is valid free species, its cantus firmus a voice
# that keeps to whole notes. So the free species guidelines must accept Fux's
# fifth species in both voices.
#
# Only the four new guidelines are asserted. The inherited two-part craft
# already marks some of Fux's lines under fifth_species, and the species specs
# and the fifth-species-published-examples story cover it.
describe HeadMusic::Style::Guides::FreeSpeciesHarmony do
  guidelines = HeadMusic::Style::Guidelines

  free_species_guidelines = [
    guidelines::FreeDissonanceTreatment,
    guidelines::ClausulaVera,
    guidelines::IndependentTextures,
    guidelines::AllowFreeSpeciesRhythmicValues
  ].freeze

  # Fux's liberties, excluded by name and never by loosening the comparison.
  liberties = {
    # The suspended F has moved on to C by beat 3, so it never resolves by
    # step; EmbellishedSuspensionTreatment marks the same spot under
    # fifth_species, and guide_species_diagonal_spec names it too.
    guidelines::FreeDissonanceTreatment => ["Fux chapter five figure 85b"]
  }.freeze

  # A fixture with expected messages is a written fault, not a model.
  examples = fux_fifth_species_examples.reject { |example| example.expected_messages.any? }

  it "covers the Fux fifth-species examples" do
    expect(examples.length).to be >= 12
  end

  free_species_guidelines.each do |guideline|
    describe guideline.name.split("::").last do
      examples.each do |example|
        next if liberties.fetch(guideline, []).include?(example.source)

        it "leaves no marks on either voice of #{example.source}" do
          marks = example.flow.voices.map { |voice| assess(guideline, voice).marks.map(&:code) }

          expect(marks).to all(be_empty)
        end
      end
    end
  end

  # The exclusion stays honest only while the liberty still draws the mark.
  it "still marks figure 85b under FreeDissonanceTreatment" do
    example = fux_fifth_species_examples.detect { |candidate| candidate.source == "Fux chapter five figure 85b" }

    expect(assess(guidelines::FreeDissonanceTreatment, example.counterpoint_voice).marks).not_to be_empty
  end
end
