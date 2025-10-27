require "spec_helper"

describe HeadMusic::Analysis::IntervalConsonance do
  let(:perfect_fifth) { HeadMusic::Analysis::DiatonicInterval.get("P5") }
  let(:major_third) { HeadMusic::Analysis::DiatonicInterval.get("M3") }
  let(:perfect_fourth) { HeadMusic::Analysis::DiatonicInterval.get("P4") }
  let(:major_second) { HeadMusic::Analysis::DiatonicInterval.get("M2") }
  let(:minor_second) { HeadMusic::Analysis::DiatonicInterval.get("m2") }
  let(:tritone) { HeadMusic::Analysis::DiatonicInterval.get("A4") }

  describe "#initialize" do
    context "with a Tradition object" do
      let(:tradition) { HeadMusic::Style::ModernTradition.new }
      let(:analysis) { described_class.new(perfect_fifth, tradition) }

      it "uses the provided tradition object directly" do
        expect(analysis.style_tradition).to be(tradition)
      end
    end

    context "with a symbol tradition name" do
      let(:analysis) { described_class.new(perfect_fifth, :renaissance_counterpoint) }

      it "creates the appropriate tradition from the symbol" do
        expect(analysis.style_tradition).to be_a(HeadMusic::Style::RenaissanceTradition)
      end
    end

    context "with default tradition" do
      let(:analysis) { described_class.new(perfect_fifth) }

      it "defaults to ModernTradition" do
        expect(analysis.style_tradition).to be_a(HeadMusic::Style::ModernTradition)
      end
    end
  end

  describe "#classification" do
    it "delegates to the style tradition" do
      analysis = described_class.new(perfect_fifth, :modern)
      expect(analysis.classification).to eq(HeadMusic::Rudiment::Consonance::PERFECT_CONSONANCE)
    end

    it "caches the classification result" do
      analysis = described_class.new(perfect_fifth, :modern)
      allow(analysis.style_tradition).to receive(:consonance_classification).and_return(HeadMusic::Rudiment::Consonance::PERFECT_CONSONANCE)
      2.times { analysis.classification } # Call twice - should only call tradition once due to caching
      expect(analysis.style_tradition).to have_received(:consonance_classification).once
    end
  end

  describe "#consonance" do
    it "returns a Consonance object based on classification" do
      analysis = described_class.new(perfect_fifth, :modern)
      consonance = analysis.consonance

      expect(consonance).to be_a(HeadMusic::Rudiment::Consonance)
      expect(consonance.name).to eq(HeadMusic::Rudiment::Consonance::PERFECT_CONSONANCE)
    end

    it "caches the consonance result" do
      analysis = described_class.new(perfect_fifth, :modern)

      # Call twice - should return the same object due to caching
      first_call = analysis.consonance
      second_call = analysis.consonance
      expect(first_call).to be(second_call)
    end
  end

  describe "predicate methods" do
    context "with perfect consonance (perfect fifth in modern tradition)" do
      let(:analysis) { described_class.new(perfect_fifth, :modern) }

      it { expect(analysis).to be_consonant }
      it { expect(analysis).to be_perfect_consonance }
      it { expect(analysis).not_to be_dissonant }
      it { expect(analysis).not_to be_imperfect_consonance }
      it { expect(analysis).not_to be_contextual }
      it { expect(analysis).not_to be_mild_dissonance }
      it { expect(analysis).not_to be_harsh_dissonance }
      it { expect(analysis).not_to be_dissonance }
    end

    context "with imperfect consonance (major third in modern tradition)" do
      let(:analysis) { described_class.new(major_third, :modern) }

      it { expect(analysis).to be_consonant }
      it { expect(analysis).to be_imperfect_consonance }
      it { expect(analysis).not_to be_dissonant }
      it { expect(analysis).not_to be_perfect_consonance }
      it { expect(analysis).not_to be_contextual }
      it { expect(analysis).not_to be_mild_dissonance }
      it { expect(analysis).not_to be_harsh_dissonance }
      it { expect(analysis).not_to be_dissonance }
    end

    context "with mild dissonance (major second in modern tradition)" do
      let(:analysis) { described_class.new(major_second, :modern) }

      it { expect(analysis).to be_dissonant }
      it { expect(analysis).to be_mild_dissonance }
      it { expect(analysis).not_to be_consonant }
      it { expect(analysis).not_to be_perfect_consonance }
      it { expect(analysis).not_to be_imperfect_consonance }
      it { expect(analysis).not_to be_contextual }
      it { expect(analysis).not_to be_harsh_dissonance }
      it { expect(analysis).not_to be_dissonance }
    end

    context "with harsh dissonance (minor second in modern tradition)" do
      let(:analysis) { described_class.new(minor_second, :modern) }

      it { expect(analysis).to be_dissonant }
      it { expect(analysis).to be_harsh_dissonance }
      it { expect(analysis).not_to be_consonant }
      it { expect(analysis).not_to be_perfect_consonance }
      it { expect(analysis).not_to be_imperfect_consonance }
      it { expect(analysis).not_to be_contextual }
      it { expect(analysis).not_to be_mild_dissonance }
      it { expect(analysis).not_to be_dissonance }
    end

    context "with strong dissonance (tritone in modern tradition)" do
      let(:analysis) { described_class.new(tritone, :modern) }

      it { expect(analysis).to be_dissonant }
      it { expect(analysis).to be_dissonance }
      it { expect(analysis).not_to be_consonant }
      it { expect(analysis).not_to be_perfect_consonance }
      it { expect(analysis).not_to be_imperfect_consonance }
      it { expect(analysis).not_to be_contextual }
      it { expect(analysis).not_to be_mild_dissonance }
      it { expect(analysis).not_to be_harsh_dissonance }
    end

    context "with contextual interval (perfect fourth in modern tradition)" do
      let(:analysis) { described_class.new(perfect_fourth, :modern) }

      it { expect(analysis).to be_contextual }
      it { expect(analysis).not_to be_consonant }
      it { expect(analysis).not_to be_dissonant }
      it { expect(analysis).not_to be_perfect_consonance }
      it { expect(analysis).not_to be_imperfect_consonance }
      it { expect(analysis).not_to be_mild_dissonance }
      it { expect(analysis).not_to be_harsh_dissonance }
      it { expect(analysis).not_to be_dissonance }
    end
  end

  describe "tradition-specific behavior" do
    context "with perfect fourth" do
      it "is contextual in modern tradition" do
        analysis = described_class.new(perfect_fourth, :modern)
        expect(analysis).to be_contextual
        expect(analysis).not_to be_consonant
        expect(analysis).not_to be_dissonant
      end

      it "is dissonant in renaissance tradition" do
        analysis = described_class.new(perfect_fourth, :renaissance_counterpoint)
        expect(analysis).to be_dissonant
        expect(analysis).to be_dissonance
      end

      it "is consonant in medieval tradition" do
        analysis = described_class.new(perfect_fourth, :medieval)
        expect(analysis).to be_consonant
        expect(analysis).to be_perfect_consonance
      end
    end
  end
end
