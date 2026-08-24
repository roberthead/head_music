require "spec_helper"

describe HeadMusic::Style::Guides::Configured do
  subject(:guide) { HeadMusic::Style::Guides::ContourMelody.with(contour: :arch, minimum_melodic_intervals: 2) }

  let(:composition) { HeadMusic::Notation::ABC.parse(abc) }
  let(:voice) { composition.voices.first }

  let(:abc) do
    <<~ABC
      X:1
      M:4/4
      L:1/4
      K:C
      CDEG|EDC2|
    ABC
  end

  it "is what Guides::Base.with returns" do
    expect(guide).to be_a described_class
  end

  it "exposes the guide class it configures" do
    expect(guide.guide_class).to eq HeadMusic::Style::Guides::ContourMelody
  end

  it "freezes its options, since registry entries are shared" do
    expect(guide.options).to be_frozen
  end

  describe "#assess_items" do
    it "returns one assessment per rule" do
      expect(guide.assess_items(voice).length).to eq guide.guide_items.length
    end

    it "returns guide item assessments" do
      expect(guide.assess_items(voice)).to all(be_a(HeadMusic::Style::GuideItemAssessment))
    end
  end

  describe "#guide_items" do
    it "memoizes rather than rebuilding per analysis" do
      first_resolution = guide.guide_items
      expect(guide.guide_items).to be first_resolution
    end

    it "builds the configured guide's rules, not the ancestor's" do
      expect(guide.guide_items.length).to eq 14
    end
  end

  # Scenario: a configured guide drops into GuideAssessment unchanged.
  describe "in HeadMusic::Style::GuideAssessment" do
    subject(:analysis) { HeadMusic::Style::GuideAssessment.new(guide, voice) }

    its(:guide_item_assessments) { are_expected.to all(be_a(HeadMusic::Style::GuideItemAssessment)) }
    its(:fitness) { is_expected.to eq 1.0 }
    its(:adherent?) { is_expected.to be true }

    it "reports the configured guide as the guide analyzed" do
      expect(analysis.guide).to eq guide
    end
  end

  describe "#with" do
    it "merges new options without dropping prior ones" do
      expect(guide.with(contour: :valley)).to configured_guide(
        HeadMusic::Style::Guides::ContourMelody, contour: :valley, minimum_melodic_intervals: 2
      )
    end

    it "leaves the original configuration untouched" do
      guide.with(contour: :valley)
      expect(guide.options[:contour]).to eq :arch
    end
  end

  describe "#key" do
    it "returns the registered key of an equivalent registry entry" do
      expect(guide.key).to eq "arch_contour_melody"
    end

    it "returns nil for a configuration outside the registry" do
      ad_hoc = HeadMusic::Style::Guides::ContourMelody.with(contour: :wave, minimum_melodic_intervals: 3)
      expect(ad_hoc.key).to be_nil
    end
  end

  describe "#category" do
    it "delegates to the guide class" do
      expect(guide.category).to eq :melody
    end
  end

  describe "#display_name" do
    it "names the registered configuration, not the shared class" do
      expect(guide.display_name).to eq "Arch Contour Melody"
    end

    it "falls back to the guide class's display name for an ad-hoc configuration" do
      ad_hoc = HeadMusic::Style::Guides::ContourMelody.with(contour: :wave, minimum_melodic_intervals: 3)
      expect(ad_hoc.display_name).to eq HeadMusic::Style::Guides::ContourMelody.display_name
    end
  end

  describe "equality" do
    let(:twin) { HeadMusic::Style::Guides::ContourMelody.with(contour: :arch, minimum_melodic_intervals: 2) }

    it "equals another configuration of the same class and options" do
      expect(guide).to eq twin
    end

    it "is eql? to its twin, so it can key a hash" do
      expect(guide).to eql twin
    end

    it "hashes equally with its twin" do
      expect(guide.hash).to eq twin.hash
    end

    it "dedupes with its twin" do
      expect([guide, twin].uniq.length).to eq 1
    end

    it "differs from a configuration with other options" do
      expect(guide).not_to eq guide.with(contour: :valley)
    end

    it "differs from its bare guide class" do
      expect(guide).not_to eq HeadMusic::Style::Guides::ContourMelody
    end
  end

  describe "identification" do
    it "reports the guide class name" do
      expect(guide.name).to eq "HeadMusic::Style::Guides::ContourMelody"
    end

    it "stringifies as the guide class name" do
      expect(guide.to_s).to eq "HeadMusic::Style::Guides::ContourMelody"
    end

    it "inspects as the call that would rebuild it" do
      expect(guide.inspect).to match(/ContourMelody\.with\(.*arch/)
    end
  end

  describe "wrapping a guide class with no configuration axis" do
    subject(:guide) { HeadMusic::Style::Guides::FuxCantusFirmus.with }

    it "resolves to the guide class's own guide items" do
      expect(guide.guide_items).to eq HeadMusic::Style::Guides::FuxCantusFirmus.guide_items
    end

    it "keeps the guide class's category" do
      expect(guide.category).to eq :melody
    end

    it "is not a composite, and reports its one category as a list" do
      expect(guide.composite?).to be false
      expect(guide.categories).to eq [:melody]
    end
  end
end
