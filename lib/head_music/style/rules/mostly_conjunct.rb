module HeadMusic::Style::Rules
end

class HeadMusic::Style::Rules::MostlyConjunct
  def self.analyze(voice)
    fitness = fitness(voice)
    if fitness < 1
      marks = marks(voice)
      message = "Use only notes in the key signature."
    end
    HeadMusic::Style::Annotation.new(subject: voice, fitness: fitness, marks: marks, message: message)
  end

  def self.fitness(voice)
    intervals = voice.melodic_intervals.length
    steps = voice.melodic_intervals.count { |interval| interval.step? }
    fitness = 1
    fitness *= HeadMusic::PENALTY_FACTOR if steps.to_f / intervals < 0.5
    fitness *= HeadMusic::PENALTY_FACTOR if steps.to_f / intervals < 0.25
    fitness
  end

  def self.marks(voice)
    voice.melodic_intervals.map.with_index do |interval, i|
      if !interval.step?
        HeadMusic::Style::Mark.for_all(voice.notes[i..i+1])
      end
    end
  end
end
