# Rules for second species harmony
class HeadMusic::Style::Guides::SecondSpeciesHarmony < HeadMusic::Style::Guides::SpeciesHarmony
  RULESET = [
    *HARMONIC_CORE,
    *DIMINUTION_HARMONIC_CORE,
    HeadMusic::Style::Guidelines::WeakBeatDissonanceTreatment
  ].freeze
end
