# Module for guides
module HeadMusic::Style::Guides; end

# Rules for the cantus firmus according to Fux.
class HeadMusic::Style::Guides::FuxCantusFirmus < HeadMusic::Style::Guides::SpeciesMelody
  RULESET = [
    *MELODIC_CORE,
    HeadMusic::Style::Guidelines::AlwaysMove,
    HeadMusic::Style::Guidelines::EndOnTonic,
    HeadMusic::Style::Guidelines::MinimumNotes.with(8),
    HeadMusic::Style::Guidelines::MaximumNotes.with(14),
    HeadMusic::Style::Guidelines::FrequentDirectionChanges,
    HeadMusic::Style::Guidelines::NoRests,
    HeadMusic::Style::Guidelines::NotesSameLength,
    HeadMusic::Style::Guidelines::LargeLeaps.with(
      message: "Recover large leaps by step in the opposite direction.",
      minimum: :perfect_fourth,
      descending: {minimum: :perfect_fourth, forbidden: :minor_sixth},
      recovery: %i[consonant_triad opposite_step]
    ),
    HeadMusic::Style::Guidelines::StartOnTonic,
    HeadMusic::Style::Guidelines::StepDownToFinalNote
  ].freeze
end
