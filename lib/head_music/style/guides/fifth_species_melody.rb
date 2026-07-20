# Module for guides
module HeadMusic::Style::Guides; end

# Rules for fifth species (florid) melodies
class HeadMusic::Style::Guides::FifthSpeciesMelody < HeadMusic::Style::Guides::SpeciesMelody
  RULESET = [
    *MELODIC_CORE,
    *MOVING_MELODIC_CORE,
    HeadMusic::Style::Guidelines::AllowedRhythmicValuesForFifthSpecies,
    HeadMusic::Style::Guidelines::MixedRhythmicValues
  ].freeze
end
