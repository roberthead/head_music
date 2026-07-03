# Module for guides
module HeadMusic::Style::Guides; end

# Rules for the cantus firmus according to Fux.
class HeadMusic::Style::Guides::FuxCantusFirmus < HeadMusic::Style::Guides::SpeciesMelody
  RULESET = [
    *MELODIC_CORE,
    HeadMusic::Style::Guidelines::AlwaysMove,
    HeadMusic::Style::Guidelines::EndOnTonic,
    HeadMusic::Style::Guidelines::FrequentDirectionChanges,
    HeadMusic::Style::Guidelines::MinimumNotes.with(8),
    HeadMusic::Style::Guidelines::MaximumNotes.with(14),
    HeadMusic::Style::Guidelines::NoRests,
    HeadMusic::Style::Guidelines::NotesSameLength,
    HeadMusic::Style::Guidelines::RecoverLargeLeaps,
    HeadMusic::Style::Guidelines::StartOnTonic,
    HeadMusic::Style::Guidelines::StepDownToFinalNote
  ].freeze
end
