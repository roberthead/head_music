# frozen_string_literal: true

# Module for guides
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
    HeadMusic::Style::Guidelines::PreferImperfect
  ].freeze

  def self.analyze(voice)
    RULESET.map { |rule| rule.new(voice) }
  end
end

# TODO: Guideline against leaping into P8 even by contrary motion.
# TODO: Guideline allowing oblique motion < ~15% of the time.
# TODO: Guideline against battuta (10-8 not at cadence, unless 10-8-6 voice exchange)
# TODO: 16th C: No M6 leaps. m6 leaps ascending only.
# TODO: 16th C (?): Avoid perfect consonances on consecutive downbeats
# TODO: 16th C: No 5-7-1 ending
# TODO: 16th C Cantus Firmus: Raise the 7 in the cadence, except in Phrygian
