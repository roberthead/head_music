# Module for guides
module HeadMusic::Style::Guides; end

# Base class for species melody guides. Inherits analysis behavior from Base;
# exists as a semantic marker distinguishing melody guides from harmony guides.
class HeadMusic::Style::Guides::SpeciesMelody < HeadMusic::Style::Guides::Base
  # Guidelines shared by every melodic guide. Subclasses splat this into their
  # RULESET: RULESET = [*MELODIC_CORE, ...species-specific rules].
  MELODIC_CORE = [
    HeadMusic::Style::Guidelines::ConsonantClimax,
    HeadMusic::Style::Guidelines::Diatonic,
    HeadMusic::Style::Guidelines::LimitOctaveLeaps,
    HeadMusic::Style::Guidelines::MostlyConjunct,
    HeadMusic::Style::Guidelines::SingableIntervals,
    HeadMusic::Style::Guidelines::SingableRange
  ].freeze
end
