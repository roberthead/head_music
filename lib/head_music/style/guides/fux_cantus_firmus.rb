# Module for guides
module HeadMusic::Style::Guides; end

# Rules for the cantus firmus according to Fux.
class HeadMusic::Style::Guides::FuxCantusFirmus < HeadMusic::Style::Guides::SpeciesMelody
  # Two questions, asked separately: three notes is whether this is a melody at
  # all, the prescription is a judgment about one that exists. A short line is
  # told it is short without being marked down on a climax never assessed.
  gate_items(*MELODIC_GATES)

  primary_items(
    *MELODIC_CORE,
    HeadMusic::Style::Guidelines::AlwaysMove,
    HeadMusic::Style::Guidelines::EndOnTonic,
    HeadMusic::Style::Guidelines::MinimumNotes.with(8),
    HeadMusic::Style::Guidelines::MaximumNotes.with(14),
    HeadMusic::Style::Guidelines::FrequentDirectionChanges,
    HeadMusic::Style::Guidelines::NoRests,
    HeadMusic::Style::Guidelines::NotesSameLength,
    HeadMusic::Style::Guidelines::LargeLeaps.with(
      violation_key: "guidelines.large_leaps.violations.fux_cantus_firmus",
      minimum: :perfect_fourth,
      descending: {minimum: :perfect_fourth, forbidden: :minor_sixth},
      recovery: %i[consonant_triad opposite_step]
    ),
    HeadMusic::Style::Guidelines::StartOnTonic,
    HeadMusic::Style::Guidelines::StepDownToFinalNote
  )
end
