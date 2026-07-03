# Module for guides
module HeadMusic::Style::Guides; end

# Rules for combined first, second, and third species melodies
class HeadMusic::Style::Guides::CombinedFirstSecondThirdSpeciesMelody < HeadMusic::Style::Guides::SpeciesMelody
  RULESET = [
    *MELODIC_CORE,
    HeadMusic::Style::Guidelines::AllowedRhythmicValuesForCombined123,
    HeadMusic::Style::Guidelines::AlwaysMove,
    HeadMusic::Style::Guidelines::EndOnTonic,
    HeadMusic::Style::Guidelines::FrequentDirectionChanges,
    HeadMusic::Style::Guidelines::NoRestsAfterNote,
    HeadMusic::Style::Guidelines::PrepareOctaveLeaps,
    HeadMusic::Style::Guidelines::StartOnPerfectConsonance,
    HeadMusic::Style::Guidelines::StepUpToFinalNote
  ].freeze
end
