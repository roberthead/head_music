module HeadMusic::Style::Rules
end

class HeadMusic::Style::Rules::UpToThirteenNotes
  MAXIMUM_NOTES = 13

  def self.analyze(voice)
    fitness = fitness(voice)
    if fitness < 1
      mark = mark(voice)
    end
    message = "Remove notes until you have at most thirteen notes." if fitness < 1
    HeadMusic::Style::Annotation.new(subject: voice, fitness: fitness, marks: mark, message: message)
  end

  def self.fitness(voice)
    overage = voice.notes.length - MAXIMUM_NOTES
    overage > 0 ? HeadMusic::PENALTY_FACTOR**overage : 1
  end

  def self.mark(voice)
    Style::Mark.for_all(voice.notes[13..-1])
  end
end
