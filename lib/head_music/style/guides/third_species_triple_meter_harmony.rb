# Rules for triple meter harmony
class HeadMusic::Style::Guides::ThirdSpeciesTripleMeterHarmony < HeadMusic::Style::Guides::SpeciesHarmony
  RULESET = diminution_ruleset(
    HeadMusic::Style::Guidelines::TripleMeterDissonanceTreatment
  )
end
