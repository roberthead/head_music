# Rules for second species harmony
class HeadMusic::Style::Guides::SecondSpeciesHarmony < HeadMusic::Style::Guides::SpeciesHarmony
  gate_items(*HARMONIC_GATES)

  primary_items(HeadMusic::Style::Guidelines::WeakBeatDissonanceTreatment)

  secondary_items(*DIMINUTION_HARMONIC_CRAFT)
end
