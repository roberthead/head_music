module HeadMusic::Style::Rules
end

class HeadMusic::Style::Rules::StepDownToFinalNote < HeadMusic::Style::Rule
  def self.analyze(voice)
    fitness = fitness(voice)
    if fitness < 1
      message = 'Step down to final note.'
      mark = HeadMusic::Style::Mark.for_all(voice.notes[-2..-1])
    end
    HeadMusic::Style::Annotation.new(subject: voice, fitness: fitness, marks: mark, message: message)
  end

  def self.fitness(voice)
    return 1 unless voice.notes.length >= 2
    fitness = 1
    fitness *= HeadMusic::PENALTY_FACTOR unless step?(voice)
    fitness *= HeadMusic::PENALTY_FACTOR unless descending?(voice)
    fitness
  end

  def self.descending?(voice)
    last_melodic_interval(voice).descending?
  end

  def self.step?(voice)
    last_melodic_interval(voice).step?
  end

  def self.last_melodic_interval(voice)
    @last_melodic_interval ||= {}
    @last_melodic_interval[voice] ||= voice.melodic_intervals.last
  end
end
