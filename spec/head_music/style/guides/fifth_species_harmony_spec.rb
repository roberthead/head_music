require "spec_helper"

describe HeadMusic::Style::Guides::FifthSpeciesHarmony do
  subject(:analysis) { HeadMusic::Style::GuideAssessment.new(described_class, voice) }

  specify { expect(guidelines_of(described_class)).to include HeadMusic::Style::Guidelines::ApproachPerfectionContrarily }
  specify { expect(guidelines_of(described_class)).to include HeadMusic::Style::Guidelines::AvoidCrossingVoices }
  specify { expect(guidelines_of(described_class)).to include HeadMusic::Style::Guidelines::AvoidOverlappingVoices }
  specify { expect(guidelines_of(described_class)).to include HeadMusic::Style::Guidelines::ConsonantDownbeats }
  specify { expect(guidelines_of(described_class)).to include HeadMusic::Style::Guidelines::NoParallelPerfectAcrossBarline }
  specify { expect(guidelines_of(described_class)).to include HeadMusic::Style::Guidelines::NoParallelPerfectOnDownbeats }
  specify { expect(guidelines_of(described_class)).to include HeadMusic::Style::Guidelines::NoParallelPerfectWithSyncopation }
  specify { expect(guidelines_of(described_class)).to include HeadMusic::Style::Guidelines::NoStrongBeatUnisons }
  specify { expect(guidelines_of(described_class)).to include HeadMusic::Style::Guidelines::PreferContraryMotion }
  specify { expect(guidelines_of(described_class)).to include HeadMusic::Style::Guidelines::PreferImperfect }
  specify { expect(guidelines_of(described_class)).to include HeadMusic::Style::Guidelines::FloridDissonanceTreatment }
  specify { expect(guidelines_of(described_class)).to include HeadMusic::Style::Guidelines::EmbellishedSuspensionTreatment }
  specify { expect(guidelines_of(described_class)).not_to include HeadMusic::Style::Guidelines::SuspensionTreatment }

  def item_assessment(guideline)
    analysis.guide_item_assessments.detect { |item| item.guideline == guideline }
  end

  context "with Fux's fifth-species line" do
    let(:voice) { fux_fifth_species_examples.first.counterpoint_voice }

    it "finds every embellished suspension properly treated" do
      expect(item_assessment(HeadMusic::Style::Guidelines::EmbellishedSuspensionTreatment)).to be_adherent
    end
  end

  # The suspension rule looks only at what sounds on beat 3; a dissonant
  # quarter leapt to on beat 2 is FloridDissonanceTreatment's finding.
  context "with a dissonant quarter leapt to from a suspension" do
    let(:voice) do
      HeadMusic::Notation::ABC.parse(
        species_abc(source: "leap", cantus_firmus: "D4|F4|E4|D4|]", counterpoint: "z2 A2|A2 d2-|d F c2|A4|]")
      ).counterpoint_voice
    end

    it "marks the quarter once, under florid dissonance treatment" do
      expect(item_assessment(HeadMusic::Style::Guidelines::EmbellishedSuspensionTreatment)).to be_adherent
      expect(item_assessment(HeadMusic::Style::Guidelines::FloridDissonanceTreatment).marks.map(&:code)).to eq ["3:2:000 to 3:3:000"]
    end
  end

  context "with a well-formed fifth species counterpoint" do
    let(:flow) { HeadMusic::Content::Flow.new(key_signature: "D dorian", meter: "4/4") }
    let(:voice) { flow.add_voice(role: :counterpoint) }

    before do
      flow.add_voice(role: "cantus firmus").tap do |cantus|
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

  context "with a florid counterpoint containing a fourth-species suspension" do
    let(:flow) { HeadMusic::Content::Flow.new(key_signature: "D dorian", meter: "4/4") }
    let(:voice) { flow.add_voice(role: :counterpoint) }

    before do
      flow.add_voice(role: "cantus firmus").tap do |cantus|
        %w[D4 F4 E4 D4].each.with_index(1) do |pitch, bar|
          cantus.place("#{bar}:1", :whole, pitch)
        end
      end

      # Bar 1: half rest + half A4 (P5 with D4, consonant)
      voice.place("1:3", :half, "A4")
      # Bar 2: half A4 (M3 with F4), then whole D5 at 2:3 (M6 with F4 = preparation)
      voice.place("2:1", :half, "A4")
      voice.place("2:3", :whole, "D5")
      # D5 sustains into bar 3:1 — m7 with CF E4 (dissonant suspension)
      # Bar 3: C5 at 3:3 resolves step down (m6 with E4, consonant)
      voice.place("3:3", :half, "C5")
      # Bar 4: whole A4 (P5 with D4, consonant)
      voice.place("4:1", :whole, "A4")
    end

    it "accepts the suspension as valid" do
      expect(analysis.fitness).to be > 0.5
    end
  end
end
