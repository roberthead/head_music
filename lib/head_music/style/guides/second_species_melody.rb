# Module for guides
module HeadMusic::Style::Guides; end

# Rules for second species melodies
class HeadMusic::Style::Guides::SecondSpeciesMelody < HeadMusic::Style::Guides::SpeciesMelody
  primary_items(*moving_species_items(
    HeadMusic::Style::Guidelines::FirstBarHalfNotes,
    HeadMusic::Style::Guidelines::TwoPerBar
  ))
end
