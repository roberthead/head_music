# Module for guides
module HeadMusic::Style::Guides; end

# Rules for fifth species (florid) melodies
class HeadMusic::Style::Guides::FifthSpeciesMelody < HeadMusic::Style::Guides::SpeciesMelody
  gate_items(*MELODIC_GATES)

  species_items(*moving_species_items(
    HeadMusic::Style::Guidelines::AllowFifthSpeciesRhythmicValues,
    HeadMusic::Style::Guidelines::MixedRhythmicValues
  ))
end
