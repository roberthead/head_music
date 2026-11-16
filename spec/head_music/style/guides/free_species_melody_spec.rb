require "spec_helper"

describe HeadMusic::Style::Guides::FreeSpeciesMelody do
  let(:guidelines) { HeadMusic::Style::Guidelines }

  def tier(guide, name)
    guide.items_by_tier[name].map(&:guideline)
  end

  it "teaches the free species note values" do
    expect(tier(described_class, :primary)).to eq [guidelines::AllowFreeSpeciesRhythmicValues]
  end

  it "keeps the moving species craft as background, reaching the final by step from either side" do
    expect(tier(described_class, :secondary)).to include(guidelines::StepToFinalNote, guidelines::PreferLongBeforeShort, guidelines::AlwaysMove)
    expect(tier(described_class, :secondary)).not_to include(guidelines::StepUpToFinalNote)
  end

  it "leaves the mixture of textures to the pair of voices" do
    expect(guidelines_of(described_class)).not_to include(guidelines::MixSpeciesTextures)
  end

  it "allows dotted rhythms only when configured to" do
    expect(described_class.items_by_tier[:primary].first.config).to eq({})
    expect(described_class.with(dotted_rhythms: true).items_by_tier[:primary].first.config).to eq(dotted_rhythms: true)
  end

  it "rejects an option it does not take" do
    expect { described_class.with(bars: 8) }.to raise_error(ArgumentError, /bars/)
  end

  context "with each voice of a Fux fifth-species example" do
    it "grades both the counterpoint and the whole-note voice highly" do
      fux_fifth_species_examples.first.flow.voices.each do |voice|
        expect(described_class.assess(voice).fitness).to be > 0.9
      end
    end
  end

  context "with a voice that falls a step into its final" do
    let(:voice) { HeadMusic::Notation::ABC.parse("X:1\nM:4/4\nL:1/4\nK:Ddor\nV:upper\nd2 e f|g2 f e|f e d2|e4|d4|]\nV:lower\nD4|C4|D4|C4|D4|]\n").voices.first }

    it "does not mark the approach" do
      assessment = described_class.assess(voice)
      marked = assessment.guide_item_assessments.reject(&:adherent?).map(&:guideline)
      expect(marked).not_to include(guidelines::StepToFinalNote)
    end
  end
end
