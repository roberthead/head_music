# Module for guides
module HeadMusic::Style::Guides; end

# Rules for fifth species (florid) melodies
class HeadMusic::Style::Guides::FifthSpeciesMelody < HeadMusic::Style::Guides::SpeciesMelody
  primary_items(*moving_species_items(
    HeadMusic::Style::Guidelines::AllowedRhythmicValuesForFifthSpecies,
    HeadMusic::Style::Guidelines::MixedRhythmicValues
  ))
end
