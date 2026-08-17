require "spec_helper"

describe HeadMusic::Style::Guides::Base do
  guides = HeadMusic::Style::Guides

  # The registry is the enumeration now: entries are guide classes and the six
  # preconfigured contour guides, so the counts cover both kinds uniformly.
  entries = HeadMusic::Style::Guide.all
  melodic_guides = entries.select { |entry| entry.category == :melody }
  harmonic_guides = entries.select { |entry| entry.category == :harmony }

  it "recognizes sixteen melodic guides" do
    expect(melodic_guides.length).to eq 16
  end

  it "recognizes seven harmonic guides" do
    expect(harmonic_guides.length).to eq 7
  end

  # Guards the explicit registry list against drift when a guide class is added.
  # The const_defined?(:RULESET, false) filter excludes abstract bases and the
  # PermissiveGuide that analysis_spec.rb injects into the namespace at load.
  it "registers every guide class that defines its own ruleset" do
    classes = guides.constants.map { |const| guides.const_get(const) }
      .select { |klass| klass.is_a?(Class) && klass.const_defined?(:RULESET, false) }
    registered = entries.map { |entry| entry.is_a?(Class) ? entry : entry.guide_class }.uniq
    expect(classes - registered).to be_empty
  end

  it "round-trips every registered key" do
    expect(entries.map { |entry| HeadMusic::Style::Guide.get(entry.key) }).to eq entries
  end

  # a core guideline may appear bare or wrapped with preset options via .with(...)
  def enforced_by?(ruleset, guideline_class)
    ruleset.any? do |rule|
      rule == guideline_class ||
        (rule.is_a?(HeadMusic::Style::GuideItem) && rule.guideline == guideline_class)
    end
  end

  melodic_guides.each do |guide|
    it "#{guide.key} enforces the melodic core" do
      unenforced = guides::SpeciesMelody::MELODIC_CORE.reject { |core| enforced_by?(guide.ruleset, core) }
      expect(unenforced).to be_empty
    end
  end

  harmonic_guides.each do |guide|
    it "#{guide.key} enforces the harmonic core" do
      unenforced = guides::SpeciesHarmony::HARMONIC_CORE.reject { |core| enforced_by?(guide.ruleset, core) }
      expect(unenforced).to be_empty
    end
  end

  describe "class-level identity" do
    it "derives a key from the demodulized class name" do
      expect(guides::SalzerSchachterCantusFirmus.key).to eq "salzer_schachter_cantus_firmus"
    end

    it "derives a display name from the key" do
      expect(guides::FirstSpeciesHarmony.display_name).to eq "First Species Harmony"
    end

    it "leaves the category undeclared on the base class" do
      expect(described_class.category).to be_nil
    end

    it "declares melody on the melodic marker" do
      expect(guides::SpeciesMelody.category).to eq :melody
    end

    it "declares harmony on the harmonic marker" do
      expect(guides::SpeciesHarmony.category).to eq :harmony
    end
  end

  describe ".ruleset" do
    it "reads the guide's own frozen ruleset constant" do
      expect(guides::FuxCantusFirmus.ruleset).to be guides::FuxCantusFirmus::RULESET
    end
  end

  describe ".with" do
    it "pairs a guide class with configuration" do
      expect(guides::FuxCantusFirmus.with).to be_a(guides::Configured)
    end

    # The raise blocks contain no analyze: a spec that configured and then
    # analyzed would pass on a guide that deferred the failure to grading time,
    # which is the thing being ruled out.
    it "rejects an option on a guide that takes no configuration" do
      expect { guides::FuxCantusFirmus.with(bogus: 1) }.to raise_error(ArgumentError, /bogus/)
    end

    it "names the guide that took no configuration" do
      expect { guides::FuxCantusFirmus.with(bogus: 1) }.to raise_error(/FuxCantusFirmus takes no configuration/)
    end
  end
end
