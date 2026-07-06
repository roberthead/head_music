require "spec_helper"

describe HeadMusic::Style::Guides::Base do
  guides = HeadMusic::Style::Guides
  all_guides = guides.constants.map { |const| guides.const_get(const) }.select { |klass| klass.is_a?(Class) }
  melodic_guides = all_guides.select { |klass| klass < guides::SpeciesMelody && klass.const_defined?(:RULESET, false) }
  harmonic_guides = all_guides.select { |klass| klass < guides::SpeciesHarmony && klass.const_defined?(:RULESET, false) }

  it "recognizes sixteen melodic guides" do
    expect(melodic_guides.length).to eq 16
  end

  it "recognizes seven harmonic guides" do
    expect(harmonic_guides.length).to eq 7
  end

  # a core guideline may appear bare or wrapped with preset options via .with(...)
  def enforced_by?(ruleset, guideline_class)
    ruleset.any? do |rule|
      rule == guideline_class ||
        (rule.is_a?(HeadMusic::Style::Annotation::Configured) && rule.guideline_class == guideline_class)
    end
  end

  melodic_guides.each do |guide|
    it "#{guide.name.split("::").last} enforces the melodic core" do
      unenforced = guides::SpeciesMelody::MELODIC_CORE.reject { |core| enforced_by?(guide::RULESET, core) }
      expect(unenforced).to be_empty
    end
  end

  harmonic_guides.each do |guide|
    it "#{guide.name.split("::").last} enforces the harmonic core" do
      unenforced = guides::SpeciesHarmony::HARMONIC_CORE.reject { |core| enforced_by?(guide::RULESET, core) }
      expect(unenforced).to be_empty
    end
  end
end
