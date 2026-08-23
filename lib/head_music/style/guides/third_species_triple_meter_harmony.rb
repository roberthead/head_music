# Rules for triple meter harmony
class HeadMusic::Style::Guides::ThirdSpeciesTripleMeterHarmony < HeadMusic::Style::Guides::SpeciesHarmony
  gate_items(*HARMONIC_GATES)

  species_items(*diminution_items(
    HeadMusic::Style::Guidelines::TripleMeterDissonanceTreatment
  ))
end
