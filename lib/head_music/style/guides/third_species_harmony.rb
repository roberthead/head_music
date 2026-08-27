# Rules for third species harmony
class HeadMusic::Style::Guides::ThirdSpeciesHarmony < HeadMusic::Style::Guides::SpeciesHarmony
  gate_items(*HARMONIC_GATES)

  primary_items(HeadMusic::Style::Guidelines::ThirdSpeciesDissonanceTreatment)

  secondary_items(*DIMINUTION_HARMONIC_CRAFT)
end
