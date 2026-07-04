# Module for guides
module HeadMusic::Style::Guides; end

# Cantus firmus rules after Salzer & Schachter, Counterpoint in Composition (1969).
class HeadMusic::Style::Guides::SalzerSchachterCantusFirmus < HeadMusic::Style::Guides::SpeciesMelody
  RULESET = [
    *MELODIC_CORE,
    HeadMusic::Style::Guidelines::AlwaysMove,
    HeadMusic::Style::Guidelines::EndOnTonic,
    HeadMusic::Style::Guidelines::MinimumNotes.with(8),
    HeadMusic::Style::Guidelines::MaximumNotes.with(14),
    HeadMusic::Style::Guidelines::ModerateDirectionChanges,
    HeadMusic::Style::Guidelines::NoRests,
    HeadMusic::Style::Guidelines::NotesSameLength,
    HeadMusic::Style::Guidelines::PrepareOctaveLeaps,
    HeadMusic::Style::Guidelines::LargeLeaps.with(
      minimum: :perfect_fourth,
      recovery: %i[consonant_triad any_step repetition opposite_leap_within]
    ),
    HeadMusic::Style::Guidelines::StartOnTonic,
    HeadMusic::Style::Guidelines::StepToFinalNote
  ].freeze
end
