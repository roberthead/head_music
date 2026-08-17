# Module for guides
module HeadMusic::Style::Guides; end

# Rules for combined first, second, and third species harmony
class HeadMusic::Style::Guides::CombinedFirstSecondThirdSpeciesHarmony < HeadMusic::Style::Guides::SpeciesHarmony
  primary_items(
    *HARMONIC_CORE,
    HeadMusic::Style::Guidelines::FloridDissonanceTreatment
  )
end
