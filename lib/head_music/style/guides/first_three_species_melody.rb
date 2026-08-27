# Module for guides
module HeadMusic::Style::Guides; end

# Rules for melodies combining the first three species
class HeadMusic::Style::Guides::FirstThreeSpeciesMelody < HeadMusic::Style::Guides::SpeciesMelody
  gate_items(*MELODIC_GATES)

  primary_items(HeadMusic::Style::Guidelines::AllowWholeHalfQuarterNotes)

  secondary_items(
    *MELODIC_CORE,
    HeadMusic::Style::Guidelines::AlwaysMove,
    HeadMusic::Style::Guidelines::EndOnTonic,
    HeadMusic::Style::Guidelines::FrequentDirectionChanges,
    HeadMusic::Style::Guidelines::NoRestsAfterNote,
    HeadMusic::Style::Guidelines::PrepareOctaveLeaps,
    HeadMusic::Style::Guidelines::StartOnPerfectConsonance,
    HeadMusic::Style::Guidelines::StepUpToFinalNote
  )
end
