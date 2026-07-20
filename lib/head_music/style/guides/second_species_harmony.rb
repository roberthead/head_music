# Rules for second species harmony
class HeadMusic::Style::Guides::SecondSpeciesHarmony < HeadMusic::Style::Guides::SpeciesHarmony
  RULESET = diminution_ruleset(
    HeadMusic::Style::Guidelines::WeakBeatDissonanceTreatment
  )
end
