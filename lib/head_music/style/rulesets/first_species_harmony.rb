module HeadMusic::Style::Rulesets
end

class HeadMusic::Style::Rulesets::FirstSpeciesHarmony
  RULESET = [
    HeadMusic::Style::Annotations::ApproachPerfectionContrarily,
    HeadMusic::Style::Annotations::AvoidCrossingVoices,
    HeadMusic::Style::Annotations::AvoidOverlappingVoices,
    HeadMusic::Style::Annotations::ConsonantDownbeats,
    HeadMusic::Style::Annotations::NoUnisonsInMiddle,
    HeadMusic::Style::Annotations::OneToOne,
    HeadMusic::Style::Annotations::PreferContraryMotion,
    HeadMusic::Style::Annotations::PreferImperfect,
  ].freeze

  def self.analyze(voice)
    RULESET.map { |rule| rule.new(voice) }
  end
end
