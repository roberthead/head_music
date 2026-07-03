# Module for guides
module HeadMusic::Style::Guides; end

# Modern rules for the cantus firmus
class HeadMusic::Style::Guides::ModernCantusFirmus < HeadMusic::Style::Guides::SpeciesMelody
  RULESET = [
    *MELODIC_CORE,
    HeadMusic::Style::Guidelines::AlwaysMove,
    HeadMusic::Style::Guidelines::AtLeastEightNotes,
    HeadMusic::Style::Guidelines::EndOnTonic,
    HeadMusic::Style::Guidelines::ModerateDirectionChanges,
    HeadMusic::Style::Guidelines::NoRests,
    HeadMusic::Style::Guidelines::NotesSameLength,
    HeadMusic::Style::Guidelines::PrepareOctaveLeaps,
    HeadMusic::Style::Guidelines::SingleLargeLeaps,
    HeadMusic::Style::Guidelines::StartOnTonic,
    HeadMusic::Style::Guidelines::StepToFinalNote,
    HeadMusic::Style::Guidelines::UpToFourteenNotes
  ].freeze
end
