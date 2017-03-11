module HeadMusic::Style::Rules
end

class HeadMusic::Style::Rules::StartOnTonic
  def self.analyze(voice)
    fitness = fitness(voice)
    if fitness < 1
      message = 'Start on the tonic.'
      mark = HeadMusic::Style::Mark.for(voice.notes.last)
    end
    HeadMusic::Style::Annotation.new(subject: voice, fitness: fitness, marks: mark, message: message)
  end

  def self.fitness(voice)
    return 1 if voice.notes.empty?
    return 1 if starts_on_tonic?(voice)
    HeadMusic::PENALTY_FACTOR
  end

  def self.starts_on_tonic?(voice)
    voice.notes &&
    voice.notes.first &&
    voice.composition &&
    voice.composition.key_signature &&
    voice.composition.key_signature.tonic_spelling == voice.notes.first.spelling
  end
end
