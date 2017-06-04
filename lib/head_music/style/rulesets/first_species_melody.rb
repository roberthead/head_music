module HeadMusic::Style::Rulesets
end

class HeadMusic::Style::Rulesets::FirstSpeciesMelody
  RULESET = [
    HeadMusic::Style::Annotations::OneToOne,
    HeadMusic::Style::Annotations::NotesSameLength,
    HeadMusic::Style::Annotations::SingableIntervals,
    HeadMusic::Style::Annotations::StartOnPerfectConsonance,
    HeadMusic::Style::Annotations::EndOnPerfectConsonance,
    HeadMusic::Style::Annotations::StepUpToFinalNote,
    HeadMusic::Style::Annotations::SingableRange,
    HeadMusic::Style::Annotations::LimitOctaveLeaps,
  ]

  def self.analyze(voice)
    RULESET.map { |rule| rule.new(voice) }
  end
end
