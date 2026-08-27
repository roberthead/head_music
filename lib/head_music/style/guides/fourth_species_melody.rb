# Module for guides
module HeadMusic::Style::Guides; end

# Rules for fourth species melodies
class HeadMusic::Style::Guides::FourthSpeciesMelody < HeadMusic::Style::Guides::SpeciesMelody
  gate_items(*MELODIC_GATES)

  primary_items(HeadMusic::Style::Guidelines::OneToOneWithTies)

  secondary_items(*MOVING_MELODIC_CRAFT)
end
