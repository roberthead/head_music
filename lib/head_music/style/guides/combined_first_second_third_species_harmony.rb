# Module for guides
module HeadMusic::Style::Guides; end

# Rules for combined first, second, and third species harmony
class HeadMusic::Style::Guides::CombinedFirstSecondThirdSpeciesHarmony < HeadMusic::Style::Guides::SpeciesHarmony
  RULESET = [
    *HARMONIC_CORE,
    HeadMusic::Style::Guidelines::FloridDissonanceTreatment
  ].freeze
end
