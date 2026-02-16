# Module for guides
module HeadMusic::Style::Guides; end

# Rules for third species harmony
class HeadMusic::Style::Guides::ThirdSpeciesHarmony
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
    HeadMusic::Style::Guidelines::ThirdSpeciesDissonanceTreatment
  ].freeze

  def self.analyze(voice)
    RULESET.map { |rule| rule.new(voice) }
  end
end
