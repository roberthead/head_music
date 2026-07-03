# Module for guides
module HeadMusic::Style::Guides; end

# Rules for triple meter melodies
class HeadMusic::Style::Guides::ThirdSpeciesTripleMeterMelody < HeadMusic::Style::Guides::SpeciesMelody
  RULESET = [
    *MELODIC_CORE,
    HeadMusic::Style::Guidelines::AlwaysMove,
    HeadMusic::Style::Guidelines::EndOnTonic,
    HeadMusic::Style::Guidelines::FirstBarQuarterNotes,
    HeadMusic::Style::Guidelines::FrequentDirectionChanges,
    HeadMusic::Style::Guidelines::NoRestsAfterNote,
    HeadMusic::Style::Guidelines::NoteFillsFinalBar,
    HeadMusic::Style::Guidelines::PrepareOctaveLeaps,
    HeadMusic::Style::Guidelines::StartOnPerfectConsonance,
    HeadMusic::Style::Guidelines::StepOutOfUnison,
    HeadMusic::Style::Guidelines::StepUpToFinalNote,
    HeadMusic::Style::Guidelines::ThreePerBar
  ].freeze
end
