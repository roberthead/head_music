module HeadMusic::Style::Rules
end

class HeadMusic::Style::Rules::LimitRange < HeadMusic::Style::Rule
  MAXIMUM_RANGE = 10

  def self.analyze(voice)
    fitness = fitness(voice)
    if fitness < 1
      message = 'Limit melodic range to a 10th.'
      marks = marks(voice)
    end
    HeadMusic::Style::Annotation.new(subject: voice, fitness: fitness, marks: marks, message: message)
  end

  def self.fitness(voice)
    return 1 unless voice.notes.length > 0
    HeadMusic::PENALTY_FACTOR**overage(voice)
  end

  def self.overage(voice)
    voice.notes.length > 0 ? [voice.range.number - MAXIMUM_RANGE, 0].max : 0
  end

  def self.marks(voice)
    if voice.notes
      extremes = (voice.highest_notes + voice.lowest_notes).sort
      HeadMusic::Style::Mark.for_each(extremes)
    end
  end
end
