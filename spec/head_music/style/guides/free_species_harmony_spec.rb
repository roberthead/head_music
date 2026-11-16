require "spec_helper"

describe HeadMusic::Style::Guides::FreeSpeciesHarmony do
  let(:guidelines) { HeadMusic::Style::Guidelines }

  def tier(guide, name)
    guide.items_by_tier[name].map(&:guideline)
  end

  def flow_for(upper, lower)
    HeadMusic::Notation::ABC.parse(<<~ABC)
      X:1
      M:4/4
      L:1/4
      K:Ddor
      V:upper
      #{upper}
      V:lower
      #{lower}
    ABC
  end

  def marked_guidelines(guide, voice)
    guide.assess(voice).guide_item_assessments.reject(&:adherent?).map(&:guideline)
  end

  describe "tiers" do
    it "teaches free dissonance treatment, the clausula vera, and independent textures" do
      expect(tier(described_class, :primary))
        .to eq [guidelines::FreeDissonanceTreatment, guidelines::ClausulaVera, guidelines::IndependentTextures]
    end

    it "keeps the inherited two-part craft as background" do
      expect(tier(described_class, :secondary)).to match_array described_class::INHERITED_HARMONIC_CRAFT
    end

    it "adds BarCount to the background only when a length is configured" do
      expect(guidelines_of(described_class)).not_to include(guidelines::BarCount)
      expect(tier(described_class.with(bars: 8..12), :secondary)).to include(guidelines::BarCount)
    end

    it "reads an Integer number of bars as an exact count" do
      bar_count = described_class.with(bars: 8).items_by_tier[:secondary].detect { |item| item.guideline == guidelines::BarCount }
      expect(bar_count.config).to eq(bars: 8..8)
    end

    it "leaves the primary tier alone when a length is configured" do
      expect(described_class.with(bars: 8..).items_by_tier[:primary]).to eq described_class.items_by_tier[:primary]
    end
  end

  # A Fux fifth-species exercise is valid free species, its cantus firmus a
  # voice that keeps to whole notes.
  context "with Fux's figure 83" do
    let(:flow) { fux_fifth_species_examples.detect { |example| example.source.end_with?("figure 83") }.flow }

    it "grades both voices perfectly" do
      expect(flow.voices.map { |voice| described_class.assess(voice).fitness }).to eq [1.0, 1.0]
    end
  end

  describe "written faults" do
    context "with an unprepared downbeat dissonance" do
      let(:flow) { flow_for("a4|g4|f2 e2|^c4|d4|]", "D4|A,4|D2 C2|E4|D4|]") }

      it "marks the dissonance, as both dissonance rules see it" do
        expect(marked_guidelines(described_class, flow.voices.first))
          .to contain_exactly(guidelines::FreeDissonanceTreatment, guidelines::ConsonantDownbeats)
      end
    end

    context "with parallel fifths from beat to beat" do
      let(:flow) { flow_for("a4|f g a2|f2 e2|^c4|d4|]", "D4|D C D2|D2 C2|E4|D4|]") }

      it "marks the parallels" do
        expect(marked_guidelines(described_class, flow.voices.first)).to eq [guidelines::NoParallelPerfectWithSyncopation]
      end
    end

    context "with both voices in quarters for three bars" do
      let(:flow) { flow_for("a g f e|f g a b|a g f e|^c4|d4|]", "D E F G|A, B, C D|C B, A, G,|E4|D4|]") }

      it "marks the shared texture" do
        expect(marked_guidelines(described_class, flow.voices.first)).to eq [guidelines::IndependentTextures]
      end
    end

    context "with a cadence in which both voices step the same way" do
      let(:flow) { flow_for("a4|f4|e4|d4|]", "F4|A,4|E4|D4|]") }

      it "marks the cadence" do
        expect(marked_guidelines(described_class, flow.voices.first)).to include(guidelines::ClausulaVera)
      end
    end
  end

  # How a limit is written must not change what anything else weighs.
  context "with a length limit and a dissonance fault" do
    let(:flow) { flow_for("a4|g4|f2 e2|f2 g2|a2 g2|f2 e2|^c4|d4|]", "D4|A,4|D4|D4|C4|D4|E4|D4|]") }

    it "grades the same under any limit the passage meets" do
      grades = [8.., 8..12, 8].map { |bars| described_class.with(bars: bars).assess(flow.voices.first).fitness }
      expect(grades.uniq.length).to eq 1
      expect(grades.first).to be < 1
    end
  end
end
