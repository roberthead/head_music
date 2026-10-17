# Module for guides
module HeadMusic::Style::Guides; end

# Rules for melodies combining the first three species
class HeadMusic::Style::Guides::FirstThreeSpeciesMelody < HeadMusic::Style::Guides::SpeciesMelody
  gate_items(*MELODIC_GATES)

  primary_items(HeadMusic::Style::Guidelines::AllowWholeHalfQuarterNotes)

  secondary_items(
    *MOVING_MELODIC_CRAFT,
    except: [HeadMusic::Style::Guidelines::NoteFillsFinalBar, HeadMusic::Style::Guidelines::StepOutOfUnison]
  )
end
