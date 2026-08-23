# Rules for third species harmony
class HeadMusic::Style::Guides::ThirdSpeciesHarmony < HeadMusic::Style::Guides::SpeciesHarmony
  gate_items(*HARMONIC_GATES)

  species_items(*diminution_items(
    HeadMusic::Style::Guidelines::ThirdSpeciesDissonanceTreatment
  ))
end
