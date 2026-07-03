# Rules for fourth species harmony
class HeadMusic::Style::Guides::FourthSpeciesHarmony < HeadMusic::Style::Guides::SpeciesHarmony
  RULESET = [
    *HARMONIC_CORE,
    HeadMusic::Style::Guidelines::NoParallelPerfectWithSyncopation,
    HeadMusic::Style::Guidelines::NoStrongBeatUnisons,
    HeadMusic::Style::Guidelines::SecondSpeciesBreak,
    HeadMusic::Style::Guidelines::SuspensionTreatment
  ].freeze
end
