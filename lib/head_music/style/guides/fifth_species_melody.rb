# Module for guides
module HeadMusic::Style::Guides; end

# Rules for fifth species (florid) melodies
class HeadMusic::Style::Guides::FifthSpeciesMelody < HeadMusic::Style::Guides::SpeciesMelody
  gate_items(*MELODIC_GATES)

  primary_items(
    HeadMusic::Style::Guidelines::AllowFifthSpeciesRhythmicValues,
    HeadMusic::Style::Guidelines::MixedRhythmicValues
  )

  secondary_items(*MOVING_MELODIC_CRAFT)
end
