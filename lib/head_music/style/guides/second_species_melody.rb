# Module for guides
module HeadMusic::Style::Guides; end

# Rules for second species melodies
class HeadMusic::Style::Guides::SecondSpeciesMelody < HeadMusic::Style::Guides::SpeciesMelody
  RULESET = [
    *MELODIC_CORE,
    *MOVING_MELODIC_CORE,
    HeadMusic::Style::Guidelines::FirstBarHalfNotes,
    HeadMusic::Style::Guidelines::TwoPerBar
  ].freeze
end
