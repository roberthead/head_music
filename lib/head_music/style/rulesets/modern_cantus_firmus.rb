module HeadMusic::Style::Rulesets
end

class HeadMusic::Style::Rulesets::ModernCantusFirmus
  RULESET = [
    HeadMusic::Style::Annotations::AlwaysMove,
    HeadMusic::Style::Annotations::AtLeastEightNotes,
    HeadMusic::Style::Annotations::ConsonantClimax,
    HeadMusic::Style::Annotations::Diatonic,
    HeadMusic::Style::Annotations::EndOnTonic,
    HeadMusic::Style::Annotations::LimitOctaveLeaps,
    HeadMusic::Style::Annotations::ModerateDirectionChanges,
    HeadMusic::Style::Annotations::MostlyConjunct,
    HeadMusic::Style::Annotations::NoRests,
    HeadMusic::Style::Annotations::NotesSameLength,
    HeadMusic::Style::Annotations::PrepareOctaveLeaps,
    HeadMusic::Style::Annotations::SingableIntervals,
    HeadMusic::Style::Annotations::SingableRange,
    HeadMusic::Style::Annotations::SingleLargeLeaps,
    HeadMusic::Style::Annotations::StartOnTonic,
    HeadMusic::Style::Annotations::StepToFinalNote,
    HeadMusic::Style::Annotations::UpToFourteenNotes,
  ]

  def self.analyze(voice)
    RULESET.map { |rule| rule.new(voice) }
  end
end
