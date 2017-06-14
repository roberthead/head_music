module HeadMusic::Style::Rulesets
end

class HeadMusic::Style::Rulesets::DavisLybbertCantusFirmus
  RULESET = [
    HeadMusic::Style::Annotations::AlwaysMove,
    HeadMusic::Style::Annotations::AtLeastEightNotes,
    HeadMusic::Style::Annotations::ConsonantClimax,
    HeadMusic::Style::Annotations::Diatonic,
    # HeadMusic::Style::Annotations::DirectionChanges,
    HeadMusic::Style::Annotations::EndOnTonic,
    HeadMusic::Style::Annotations::LimitOctaveLeaps,
    HeadMusic::Style::Annotations::MostlyConjunct,
    HeadMusic::Style::Annotations::NoRests,
    HeadMusic::Style::Annotations::NotesSameLength,
    # HeadMusic::Style::Annotations::RecoverLargeLeaps,
    HeadMusic::Style::Annotations::SingableIntervals,
    HeadMusic::Style::Annotations::SingableRange,
    HeadMusic::Style::Annotations::StartOnTonic,
    HeadMusic::Style::Annotations::StepDownToFinalNote,
    HeadMusic::Style::Annotations::UpToFourteenNotes,
  ]

  def self.analyze(voice)
    RULESET.map { |rule| rule.new(voice) }
  end
end
