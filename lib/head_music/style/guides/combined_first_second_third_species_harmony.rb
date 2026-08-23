# Module for guides
module HeadMusic::Style::Guides; end

# Rules for combined first, second, and third species harmony
class HeadMusic::Style::Guides::CombinedFirstSecondThirdSpeciesHarmony < HeadMusic::Style::Guides::SpeciesHarmony
  gate_items(*HARMONIC_GATES)

  # The diminution core, absent until now: this guide covers second and third
  # species, both of which set several notes against one, so the two rules about
  # doing that apply to it by construction.
  species_items(*diminution_items(
    HeadMusic::Style::Guidelines::FloridDissonanceTreatment
  ))
end
