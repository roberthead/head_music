module HeadMusic::Style::Rules
end

class HeadMusic::Style::Rules::EndOnTonic
  def self.analyze(voice)
    fitness = fitness(voice)
    if fitness < 1
      message = 'End on the tonic'
      mark = HeadMusic::Style::Mark.for(voice.notes.last)
    end
    HeadMusic::Style::Annotation.new(subject: voice, fitness: fitness, marks: mark, message: message)
  end

  def self.fitness(voice)
    return 1 if voice.notes.empty?
    return 1 if ends_on_tonic?(voice)
    HeadMusic::PENALTY_FACTOR
  end

  def self.ends_on_tonic?(voice)
    voice.notes &&
    voice.notes.last &&
    voice.composition &&
    voice.composition.key_signature &&
    voice.composition.key_signature.tonic_spelling == voice.notes.last.spelling
  end
end
