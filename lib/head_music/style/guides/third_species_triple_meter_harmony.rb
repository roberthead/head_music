# Rules for triple meter harmony
class HeadMusic::Style::Guides::ThirdSpeciesTripleMeterHarmony < HeadMusic::Style::Guides::SpeciesHarmony
  gate_items(*HARMONIC_GATES)

  primary_items(*diminution_items(
    HeadMusic::Style::Guidelines::TripleMeterDissonanceTreatment
  ))
end
