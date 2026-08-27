# Module for guides
module HeadMusic::Style::Guides; end

# Rules for second species melodies
class HeadMusic::Style::Guides::SecondSpeciesMelody < HeadMusic::Style::Guides::SpeciesMelody
  gate_items(*MELODIC_GATES)

  primary_items(
    HeadMusic::Style::Guidelines::FirstBarHalfNotes,
    HeadMusic::Style::Guidelines::TwoPerBar
  )

  secondary_items(*MOVING_MELODIC_CRAFT)
end
