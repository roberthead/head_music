# Module for guides
module HeadMusic::Style::Guides; end

# Rules for triple meter melodies
class HeadMusic::Style::Guides::ThirdSpeciesTripleMeterMelody < HeadMusic::Style::Guides::SpeciesMelody
  RULESET = moving_species_ruleset(
    HeadMusic::Style::Guidelines::FirstBarQuarterNotes,
    HeadMusic::Style::Guidelines::ThreePerBar
  )
end
