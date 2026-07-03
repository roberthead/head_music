require "spec_helper"

describe HeadMusic::Style::Guides::Base do
  guides = HeadMusic::Style::Guides
  all_guides = guides.constants.map { |const| guides.const_get(const) }.select { |klass| klass.is_a?(Class) }
  melodic_guides = all_guides.select { |klass| klass < guides::SpeciesMelody && klass.const_defined?(:RULESET, false) }
  harmonic_guides = all_guides.select { |klass| klass < guides::SpeciesHarmony && klass.const_defined?(:RULESET, false) }

  it "recognizes ten melodic guides" do
    expect(melodic_guides.length).to eq 10
  end

  it "recognizes seven harmonic guides" do
    expect(harmonic_guides.length).to eq 7
  end

  melodic_guides.each do |guide|
    it "#{guide.name.split("::").last} enforces the melodic core" do
      expect(guide::RULESET).to include(*guides::SpeciesMelody::MELODIC_CORE)
    end
  end

  harmonic_guides.each do |guide|
    it "#{guide.name.split("::").last} enforces the harmonic core" do
      expect(guide::RULESET).to include(*guides::SpeciesHarmony::HARMONIC_CORE)
    end
  end
end
