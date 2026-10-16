# Module for guides
module HeadMusic::Style::Guides; end

# Rules for second species melodies
class HeadMusic::Style::Guides::SecondSpeciesMelody < HeadMusic::Style::Guides::SpeciesMelody
  moving_melody(
    HeadMusic::Style::Guidelines::FirstBarHalfNotes,
    HeadMusic::Style::Guidelines::TwoPerBar
  )
end
