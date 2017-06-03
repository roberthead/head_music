module HeadMusic::Style::Rulesets
end

class HeadMusic::Style::Rulesets::FirstSpeciesHarmony
  RULESET = [
    HeadMusic::Style::Annotations::ConsonantOnStrongBeats,
  ]

  def self.analyze(voice)
    RULESET.map { |rule| rule.new(voice) }
  end
end
