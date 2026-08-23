# Rules for second species harmony
class HeadMusic::Style::Guides::SecondSpeciesHarmony < HeadMusic::Style::Guides::SpeciesHarmony
  gate_items(*HARMONIC_GATES)

  species_items(*diminution_items(
    HeadMusic::Style::Guidelines::WeakBeatDissonanceTreatment
  ))
end
