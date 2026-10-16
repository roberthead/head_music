# Module for guides
module HeadMusic::Style::Guides; end

# Rules for fourth species melodies
class HeadMusic::Style::Guides::FourthSpeciesMelody < HeadMusic::Style::Guides::SpeciesMelody
  # OneToOneWithTies bounds how many notes sound against each cantus firmus
  # note; SustainAcrossBarlines asks for the ligature itself.
  moving_melody(
    HeadMusic::Style::Guidelines::OneToOneWithTies,
    HeadMusic::Style::Guidelines::SustainAcrossBarlines
  )
end
