# Module for guides
module HeadMusic::Style::Guides; end

# Rules for triple meter melodies
class HeadMusic::Style::Guides::ThirdSpeciesTripleMeterMelody < HeadMusic::Style::Guides::SpeciesMelody
  RULESET = [
    *MELODIC_CORE,
    *MOVING_MELODIC_CORE,
    HeadMusic::Style::Guidelines::FirstBarQuarterNotes,
    HeadMusic::Style::Guidelines::ThreePerBar
  ].freeze
end
