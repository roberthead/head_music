module HeadMusic::Style::Rulesets
end

class HeadMusic::Style::Rulesets::CantusFirmus
  RULESET = [
    HeadMusic::Style::Annotations::AlwaysMove,
    HeadMusic::Style::Annotations::AtLeastEightNotes,
    HeadMusic::Style::Annotations::Diatonic,
    HeadMusic::Style::Annotations::EndOnTonic,
    HeadMusic::Style::Annotations::LimitRange,
    HeadMusic::Style::Annotations::MostlyConjunct,
    HeadMusic::Style::Annotations::NoRests,
    HeadMusic::Style::Annotations::NotesSameLength,
    HeadMusic::Style::Annotations::PermittedIntervals,
    HeadMusic::Style::Annotations::RecoverLargeLeaps,
    HeadMusic::Style::Annotations::StartOnTonic,
    HeadMusic::Style::Annotations::StepDownToFinalNote,
    HeadMusic::Style::Annotations::UpToThirteenNotes,
  ]

  def self.analyze(voice)
    RULESET.map { |rule| rule.new(voice) }
  end
end
