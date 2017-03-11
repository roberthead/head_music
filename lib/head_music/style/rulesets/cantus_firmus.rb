module HeadMusic::Style::Rulesets
end

class HeadMusic::Style::Rulesets::CantusFirmus
  RULESET = [
    HeadMusic::Style::Rules::AlwaysMove,
    HeadMusic::Style::Rules::AtLeastEightNotes,
    HeadMusic::Style::Rules::Diatonic,
    HeadMusic::Style::Rules::EndOnTonic,
    HeadMusic::Style::Rules::LimitRange,
    HeadMusic::Style::Rules::MostlyConjunct,
    HeadMusic::Style::Rules::NoRests,
    HeadMusic::Style::Rules::NotesSameLength,
    HeadMusic::Style::Rules::PermittedIntervals,
    HeadMusic::Style::Rules::RecoverLeaps,
    HeadMusic::Style::Rules::StartOnTonic,
    HeadMusic::Style::Rules::StepDownToFinalNote,
    HeadMusic::Style::Rules::UpToThirteenNotes,
  ]

  def self.analyze(voice)
    RULESET.map { |rule| rule.analyze(voice) }
  end
end
