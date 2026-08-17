# Module for guides
module HeadMusic::Style::Guides; end

# Rules for third species melodies
class HeadMusic::Style::Guides::ThirdSpeciesMelody < HeadMusic::Style::Guides::SpeciesMelody
  gate_items(*MELODIC_GATES)

  primary_items(*moving_species_items(
    HeadMusic::Style::Guidelines::FirstBarQuarterNotes,
    HeadMusic::Style::Guidelines::FourPerBar
  ))
end
