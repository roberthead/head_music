module HeadMusic::Style::Rules
end

class HeadMusic::Style::Rules::CantusFirmus < HeadMusic::Style::Rule
  MINIMUM_NOTES = 7
  RULESET = [
    HeadMusic::Style::Rules::AtLeastEightNotes,
    HeadMusic::Style::Rules::UpToThirteenNotes,
    HeadMusic::Style::Rules::NoRests,
    HeadMusic::Style::Rules::StartOnTonic,
    HeadMusic::Style::Rules::EndOnTonic,
    HeadMusic::Style::Rules::StepDownToFinalNote,
    HeadMusic::Style::Rules::NotesSameLength,
  ]

  def self.fitness(voice)
    RULESET.map { |rule| rule.fitness(voice) }.reduce(1, :*)
  end

  def self.annotations(voice)
    RULESET.map { |rule| rule.annotations(voice) }.reject(&:nil?).reduce([], :+)
  end
end
