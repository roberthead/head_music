# Rules for third species harmony
class HeadMusic::Style::Guides::ThirdSpeciesHarmony < HeadMusic::Style::Guides::SpeciesHarmony
  RULESET = [
    *HARMONIC_CORE,
    HeadMusic::Style::Guidelines::NoParallelPerfectAcrossBarline,
    HeadMusic::Style::Guidelines::NoStrongBeatUnisons,
    HeadMusic::Style::Guidelines::ThirdSpeciesDissonanceTreatment
  ].freeze
end
