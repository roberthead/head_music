require "spec_helper"

describe HeadMusic::Style::Guides::CompositeGuide do
  subject(:guide) { HeadMusic::Style::Guide.get!("first_species") }

  let(:melody) { HeadMusic::Style::Guides::FirstSpeciesMelody }
  let(:harmony) { HeadMusic::Style::Guides::FirstSpeciesHarmony }

  describe "the registered composites" do
    # Spelled out rather than derived, for the reason guide_spec gives about
    # published keys: which two guides make up a species is the claim, and a
    # derivation would restate the registry instead of checking it.
    expected_members = {
      "first_species" => %w[first_species_melody first_species_harmony],
      "second_species" => %w[second_species_melody second_species_harmony],
      "third_species" => %w[third_species_melody third_species_harmony],
      "third_species_triple_meter" => %w[third_species_triple_meter_melody third_species_triple_meter_harmony],
      "fourth_species" => %w[fourth_species_melody fourth_species_harmony],
      "fifth_species" => %w[fifth_species_melody fifth_species_harmony],
      "first_three_species" => %w[first_three_species_melody first_three_species_harmony]
    }

    expected_members.each do |key, member_keys|
      it "resolves #{key} to its melody and harmony guides" do
        composite = HeadMusic::Style::Guide.get!(key)

        expect(composite).to be_a described_class
        expect(composite.guides.map(&:key)).to eq member_keys
      end
    end

    it "registers one composite per species and no more" do
      composites = HeadMusic::Style::Guide.all.select(&:composite?)

      expect(composites.map(&:key)).to match_array expected_members.keys
    end
  end

  describe "standing in for a guide class" do
    its(:composite?) { is_expected.to be true }
    its(:key) { is_expected.to eq "first_species" }
    its(:display_name) { is_expected.to eq "First Species" }
    its(:instruction) { is_expected.to be_a(String).and include("cantus firmus") }

    it "assesses through CompositeAssessment rather than GuideAssessment" do
      expect(guide.assess(HeadMusic::Content::Voice.new)).to be_a HeadMusic::Style::CompositeAssessment
    end

    it "reports its members' findings from assess_items, in member order" do
      voice = fux_first_species_examples[7].counterpoint_voice
      # By value: a GuideItemAssessment is a fresh object per call and has no
      # equality of its own, so identity would compare two correct lists as
      # different and print both in full.
      graded = ->(items) { items.map { |item| [item.guide_item, item.tier, item.fitness] } }

      expect(graded.call(guide.assess_items(voice)))
        .to eq graded.call(melody.assess_items(voice)) + graded.call(harmony.assess_items(voice))
    end
  end

  describe "#category and #categories" do
    # A composite spans its members rather than claiming one category, which is
    # why categories exists on every guide and not only on this one.
    its(:category) { is_expected.to be_nil }
    its(:categories) { is_expected.to eq %i[melody harmony] }
  end

  describe "#guide_items" do
    # For display, not for grading. The members share MinimumNotes.with(3) --
    # GuideItem equality is by value -- so the union collapses by one, while a
    # fully graded composite still reports 27 item assessments because each
    # member assesses that gate itself. The asymmetry is the design.
    it "deduplicates the gate its members share" do
      expect(melody.guide_items.length + harmony.guide_items.length).to eq 27
      expect(guide.guide_items.length).to eq 26
    end

    it "reports more assessments than items, because each member gates itself" do
      voice = fux_first_species_examples[7].counterpoint_voice

      expect(guide.assess(voice).guide_item_assessments.length).to eq 27
    end

    it "is resolved at construction, so a frozen composite never memoizes late" do
      expect(guide.instance_variable_defined?(:@guide_items)).to be true
      expect(guide).to be_frozen
    end
  end

  describe "#items_by_tier" do
    it "deduplicates within a tier rather than across the whole list" do
      expect(guide.items_by_tier[:gate].length).to eq 2
      expect(guide.items_by_tier[:gate]).to include configured(HeadMusic::Style::Guidelines::MinimumNotes, minimum: 3)
    end

    it "declares every tier its members declare" do
      HeadMusic::Style::Guides::Base::TIERS.each do |tier|
        expect(guide.items_by_tier[tier]).to be_an(Array)
      end
    end
  end

  describe "equality" do
    let(:same) { described_class.new([melody, harmony]) }
    let(:different) { described_class.new([melody, HeadMusic::Style::Guides::SecondSpeciesHarmony]) }

    it "is equal by members" do
      expect(same).to eq guide
      expect(same).to eql guide
      expect(same.hash).to eq guide.hash
    end

    it "differs when its members differ" do
      expect(different).not_to eq guide
    end

    # key_for is REGISTRY.key(guide), which compares by ==, so an equal
    # composite built by hand finds the registered one's key.
    it "lets an equal composite find the registered key" do
      expect(same.key).to eq "first_species"
    end
  end

  describe "an unregistered composite" do
    subject(:guide) { described_class.new([melody, HeadMusic::Style::Guides::SecondSpeciesHarmony]) }

    its(:key) { is_expected.to be_nil }

    it "borrows its members' names rather than claiming a key that resolves elsewhere" do
      expect(guide.display_name).to eq "#{melody.display_name} + #{HeadMusic::Style::Guides::SecondSpeciesHarmony.display_name}"
    end

    it "borrows its members' instructions" do
      expect(guide.instruction).to include melody.instruction
    end
  end

  describe "construction" do
    it "refuses a single guide, which needs no composite" do
      expect { described_class.new([melody]) }
        .to raise_error(ArgumentError, /grades more than one guide/)
    end

    # At depth two, `assessments` would have to mean both the members fitness
    # divides by and the leaves a consumer walks, and those stop being one list.
    it "refuses to hold another composite" do
      expect { described_class.new([guide, melody]) }
        .to raise_error(ArgumentError, /cannot hold another composite/)
    end
  end
end
