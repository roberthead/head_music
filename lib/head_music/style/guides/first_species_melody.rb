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
    *MELODIC_CORE,
    HeadMusic::Style::Guidelines::EndOnTonic,
    HeadMusic::Style::Guidelines::FrequentDirectionChanges,
    HeadMusic::Style::Guidelines::NoteFillsFinalBar,
    HeadMusic::Style::Guidelines::PrepareOctaveLeaps,
    HeadMusic::Style::Guidelines::StartOnPerfectConsonance,
    HeadMusic::Style::Guidelines::StepOutOfUnison,
    HeadMusic::Style::Guidelines::StepUpToFinalNote
  )
end
