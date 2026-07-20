# Rules for third species harmony
class HeadMusic::Style::Guides::ThirdSpeciesHarmony < HeadMusic::Style::Guides::SpeciesHarmony
  RULESET = diminution_ruleset(
    HeadMusic::Style::Guidelines::ThirdSpeciesDissonanceTreatment
  )
end
