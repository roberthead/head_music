# Module for guides
module HeadMusic::Style::Guides; end

# Rules for harmony in counterpoint combining the first three species
class HeadMusic::Style::Guides::FirstThreeSpeciesHarmony < HeadMusic::Style::Guides::SpeciesHarmony
  gate_items(*HARMONIC_GATES)

  primary_items(HeadMusic::Style::Guidelines::FloridDissonanceTreatment)

  # The diminution core, absent until now: this guide covers second and third
  # species, both of which set several notes against one, so the two rules about
  # doing that apply to it by construction.
  secondary_items(*DIMINUTION_HARMONIC_CRAFT)
end
