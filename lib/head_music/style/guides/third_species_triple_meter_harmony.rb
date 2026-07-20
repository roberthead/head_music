# Rules for triple meter harmony
class HeadMusic::Style::Guides::ThirdSpeciesTripleMeterHarmony < HeadMusic::Style::Guides::SpeciesHarmony
  RULESET = [
    *HARMONIC_CORE,
    *DIMINUTION_HARMONIC_CORE,
    HeadMusic::Style::Guidelines::TripleMeterDissonanceTreatment
  ].freeze
end
