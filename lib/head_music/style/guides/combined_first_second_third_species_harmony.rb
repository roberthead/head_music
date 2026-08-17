# Module for guides
module HeadMusic::Style::Guides; end

# Rules for combined first, second, and third species harmony
class HeadMusic::Style::Guides::CombinedFirstSecondThirdSpeciesHarmony < HeadMusic::Style::Guides::SpeciesHarmony
  gate_items(*HARMONIC_GATES)

  primary_items(
    *HARMONIC_CORE,
    HeadMusic::Style::Guidelines::FloridDissonanceTreatment
  )
end
