# Module for guides
module HeadMusic::Style::Guides; end

# Rules for combined second, third, and fourth species harmony
class HeadMusic::Style::Guides::CombinedSecondThirdFourthSpeciesHarmony < HeadMusic::Style::Guides::SpeciesHarmony
  RULESET = [
    HeadMusic::Style::Guidelines::ApproachPerfectionContrarily,
    HeadMusic::Style::Guidelines::AvoidCrossingVoices,
    HeadMusic::Style::Guidelines::AvoidOverlappingVoices,
    HeadMusic::Style::Guidelines::ConsonantDownbeats,
    HeadMusic::Style::Guidelines::NoParallelPerfectOnDownbeats,
    HeadMusic::Style::Guidelines::NoParallelPerfectWithSyncopation,
    HeadMusic::Style::Guidelines::PreferContraryMotion,
    HeadMusic::Style::Guidelines::PreferImperfect,
    HeadMusic::Style::Guidelines::FloridDissonanceTreatment,
    HeadMusic::Style::Guidelines::SuspensionTreatment
  ].freeze
end
