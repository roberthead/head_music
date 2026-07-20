# Module for guides
module HeadMusic::Style::Guides; end

# Rules for fourth species melodies
class HeadMusic::Style::Guides::FourthSpeciesMelody < HeadMusic::Style::Guides::SpeciesMelody
  RULESET = moving_species_ruleset(
    HeadMusic::Style::Guidelines::OneToOneWithTies
  )
end
