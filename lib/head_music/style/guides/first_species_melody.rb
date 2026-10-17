# Module for guides
module HeadMusic::Style::Guides; end

# Rules for first species melodies
class HeadMusic::Style::Guides::FirstSpeciesMelody < HeadMusic::Style::Guides::SpeciesMelody
  gate_items(*MELODIC_GATES)

  primary_items(
    HeadMusic::Style::Guidelines::FirstBarWholeNote,
    HeadMusic::Style::Guidelines::OnePerBar
  )

  # The moving craft this species can be held to. AlwaysMove and NoRestsAfterNote
  # are omitted rather than failed: both ask what happens within a bar, and a
  # first species bar is one whole note.
  secondary_items(
    *MOVING_MELODIC_CRAFT,
    except: [HeadMusic::Style::Guidelines::AlwaysMove, HeadMusic::Style::Guidelines::NoRestsAfterNote]
  )
end
