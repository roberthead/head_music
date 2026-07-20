# Module for guides
module HeadMusic::Style::Guides; end

# Rules for fifth species (florid) melodies
class HeadMusic::Style::Guides::FifthSpeciesMelody < HeadMusic::Style::Guides::SpeciesMelody
  RULESET = moving_species_ruleset(
    HeadMusic::Style::Guidelines::AllowedRhythmicValuesForFifthSpecies,
    HeadMusic::Style::Guidelines::MixedRhythmicValues
  )
end
