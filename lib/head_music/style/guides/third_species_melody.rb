# Module for guides
module HeadMusic::Style::Guides; end

# Rules for third species melodies
class HeadMusic::Style::Guides::ThirdSpeciesMelody < HeadMusic::Style::Guides::SpeciesMelody
  RULESET = [
    *MELODIC_CORE,
    *MOVING_MELODIC_CORE,
    HeadMusic::Style::Guidelines::FirstBarQuarterNotes,
    HeadMusic::Style::Guidelines::FourPerBar
  ].freeze
end
