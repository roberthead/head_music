# frozen_string_literal: true

# Module for rulesets
module HeadMusic::Style::Guides; end

# Rules for first species harmony
class HeadMusic::Style::Guides::FirstSpeciesHarmony
  RULESET = [
    HeadMusic::Style::Guidelines::ApproachPerfectionContrarily,
    HeadMusic::Style::Guidelines::AvoidCrossingVoices,
    HeadMusic::Style::Guidelines::AvoidOverlappingVoices,
    HeadMusic::Style::Guidelines::ConsonantDownbeats,
    HeadMusic::Style::Guidelines::NoUnisonsInMiddle,
    HeadMusic::Style::Guidelines::OneToOne,
    HeadMusic::Style::Guidelines::PreferContraryMotion,
    HeadMusic::Style::Guidelines::PreferImperfect,
  ].freeze

  def self.analyze(voice)
    RULESET.map { |rule| rule.new(voice) }
  end
end
