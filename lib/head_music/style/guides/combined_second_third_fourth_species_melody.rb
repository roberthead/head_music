# Module for guides
module HeadMusic::Style::Guides; end

# Rules for combined second, third, and fourth species melodies
class HeadMusic::Style::Guides::CombinedSecondThirdFourthSpeciesMelody < HeadMusic::Style::Guides::SpeciesMelody
  RULESET = [
    HeadMusic::Style::Guidelines::AlwaysMove,
    HeadMusic::Style::Guidelines::ConsonantClimax,
    HeadMusic::Style::Guidelines::Diatonic,
    HeadMusic::Style::Guidelines::EndOnTonic,
    HeadMusic::Style::Guidelines::FrequentDirectionChanges,
    HeadMusic::Style::Guidelines::LimitOctaveLeaps,
    HeadMusic::Style::Guidelines::MostlyConjunct,
    HeadMusic::Style::Guidelines::PrepareOctaveLeaps,
    HeadMusic::Style::Guidelines::SingableIntervals,
    HeadMusic::Style::Guidelines::SingableRange,
    HeadMusic::Style::Guidelines::StartOnPerfectConsonance,
    HeadMusic::Style::Guidelines::StepUpToFinalNote,
    HeadMusic::Style::Guidelines::AllowedRhythmicValuesForCombined234,
    HeadMusic::Style::Guidelines::NoRestsAfterNote
  ].freeze
end
