# Module for guides
module HeadMusic::Style::Guides; end

# Rules for third species melodies
class HeadMusic::Style::Guides::ThirdSpeciesMelody < HeadMusic::Style::Guides::SpeciesMelody
  RULESET = moving_species_ruleset(
    HeadMusic::Style::Guidelines::FirstBarQuarterNotes,
    HeadMusic::Style::Guidelines::FourPerBar
  )
end
