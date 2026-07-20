# Module for guides
module HeadMusic::Style::Guides; end

# Rules for fourth species melodies
class HeadMusic::Style::Guides::FourthSpeciesMelody < HeadMusic::Style::Guides::SpeciesMelody
  RULESET = [
    *MELODIC_CORE,
    *MOVING_MELODIC_CORE,
    HeadMusic::Style::Guidelines::OneToOneWithTies
  ].freeze
end
