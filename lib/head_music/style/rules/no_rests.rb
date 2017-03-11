module HeadMusic::Style::Rules
end

class HeadMusic::Style::Rules::NoRests < HeadMusic::Style::Rule
  def self.analyze(voice)
    rests = voice.rests
    fitness = HeadMusic::PENALTY_FACTOR**rests.length
    if rests.length > 0
      message = "Change rests to notes."
      marks = rests.map { |rest| HeadMusic::Style::Mark.for_all(rest) }
    end
    HeadMusic::Style::Annotation.new(subject: voice, fitness: fitness, marks: marks, message: message)
  end
end
