# Module for guides
module HeadMusic::Style::Guides; end

# Rules for fourth species melodies
class HeadMusic::Style::Guides::FourthSpeciesMelody < HeadMusic::Style::Guides::SpeciesMelody
  gate_items(*MELODIC_GATES)

  # OneToOneWithTies bounds how many notes sound against each cantus firmus
  # note; SustainAcrossBarlines asks for the ligature itself.
  primary_items(
    HeadMusic::Style::Guidelines::OneToOneWithTies,
    HeadMusic::Style::Guidelines::SustainAcrossBarlines
  )

  secondary_items(*MOVING_MELODIC_CRAFT)
end
