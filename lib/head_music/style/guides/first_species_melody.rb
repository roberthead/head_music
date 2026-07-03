# Module for guides
module HeadMusic::Style::Guides; end

# Rules for first species melodies
class HeadMusic::Style::Guides::FirstSpeciesMelody < HeadMusic::Style::Guides::SpeciesMelody
  RULESET = [
    *MELODIC_CORE,
    HeadMusic::Style::Guidelines::EndOnTonic,
    HeadMusic::Style::Guidelines::FirstBarWholeNote,
    HeadMusic::Style::Guidelines::FrequentDirectionChanges,
    HeadMusic::Style::Guidelines::NoteFillsFinalBar,
    HeadMusic::Style::Guidelines::OnePerBar,
    HeadMusic::Style::Guidelines::PrepareOctaveLeaps,
    HeadMusic::Style::Guidelines::StartOnPerfectConsonance,
    HeadMusic::Style::Guidelines::StepOutOfUnison,
    HeadMusic::Style::Guidelines::StepUpToFinalNote
  ].freeze
end
