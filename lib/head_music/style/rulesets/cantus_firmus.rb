module HeadMusic::Style::Rulesets
end

class HeadMusic::Style::Rulesets::CantusFirmus
  RULESET = [
    HeadMusic::Style::Rules::AlwaysMove,
    HeadMusic::Style::Rules::AtLeastEightNotes,
    HeadMusic::Style::Rules::EndOnTonic,
    HeadMusic::Style::Rules::NoRests,
    HeadMusic::Style::Rules::NotesSameLength,
    HeadMusic::Style::Rules::StartOnTonic,
    HeadMusic::Style::Rules::StepDownToFinalNote,
    HeadMusic::Style::Rules::UpToThirteenNotes,
  ]

  def self.analyze(voice)
    RULESET.map { |rule| rule.analyze(voice) }
  end
end
