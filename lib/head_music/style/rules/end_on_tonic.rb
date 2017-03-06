module HeadMusic::Style::Rules
end

class HeadMusic::Style::Rules::EndOnTonic < HeadMusic::Style::Rule
  def self.fitness(voice)
    return 0 unless voice.notes.first
    fitness = 1
    if !ends_on_tonic?(voice)
      fitness *= HeadMusic::GOLDEN_RATIO_INVERSE
    end
    fitness
  end

  def self.annotations(voice)
    if fitness(voice) < 1
      start_position = voice.notes.last ? voice.notes.last.position : "1:1"
      end_position = start_position.start_of_next_measure
      [HeadMusic::Style::Annotation.new(voice, start_position, end_position, "End on the tonic")]
    end
  end

  def self.ends_on_tonic?(voice)
    voice.notes &&
    voice.notes.last &&
    voice.composition &&
    voice.composition.key_signature &&
    voice.composition.key_signature.tonic_spelling == voice.notes.last.spelling
  end
end
