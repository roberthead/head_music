# Module for guides
module HeadMusic::Style::Guides; end

# Rules for the cantus firmus according to Fux.
class HeadMusic::Style::Guides::FuxCantusFirmus < HeadMusic::Style::Guides::SpeciesMelody
  RULESET = [
    HeadMusic::Style::Guidelines::AlwaysMove,
    HeadMusic::Style::Guidelines::AtLeastEightNotes,
    HeadMusic::Style::Guidelines::ConsonantClimax,
    HeadMusic::Style::Guidelines::Diatonic,
    HeadMusic::Style::Guidelines::EndOnTonic,
    HeadMusic::Style::Guidelines::FrequentDirectionChanges,
    HeadMusic::Style::Guidelines::LimitOctaveLeaps,
    HeadMusic::Style::Guidelines::MostlyConjunct,
    HeadMusic::Style::Guidelines::NoRests,
    HeadMusic::Style::Guidelines::NotesSameLength,
    HeadMusic::Style::Guidelines::RecoverLargeLeaps,
    HeadMusic::Style::Guidelines::SingableIntervals,
    HeadMusic::Style::Guidelines::SingableRange,
    HeadMusic::Style::Guidelines::StartOnTonic,
    HeadMusic::Style::Guidelines::StepDownToFinalNote,
    HeadMusic::Style::Guidelines::UpToFourteenNotes
  ].freeze
end
