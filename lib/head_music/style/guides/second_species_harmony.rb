# Rules for second species harmony
class HeadMusic::Style::Guides::SecondSpeciesHarmony < HeadMusic::Style::Guides::SpeciesHarmony
  RULESET = [
    HeadMusic::Style::Guidelines::ApproachPerfectionContrarily,
    HeadMusic::Style::Guidelines::AvoidCrossingVoices,
    HeadMusic::Style::Guidelines::AvoidOverlappingVoices,
    HeadMusic::Style::Guidelines::ConsonantDownbeats,
    HeadMusic::Style::Guidelines::NoParallelPerfectAcrossBarline,
    HeadMusic::Style::Guidelines::NoParallelPerfectOnDownbeats,
    HeadMusic::Style::Guidelines::NoStrongBeatUnisons,
    HeadMusic::Style::Guidelines::PreferContraryMotion,
    HeadMusic::Style::Guidelines::PreferImperfect,
    HeadMusic::Style::Guidelines::WeakBeatDissonanceTreatment
  ].freeze
end
