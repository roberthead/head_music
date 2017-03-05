module HeadMusic::Style::Rules
end

class HeadMusic::Style::Rules::StartOnTonic < HeadMusic::Style::Rule
  def self.fitness(voice)
    return 0 unless voice.notes.first
    score = 1
    if !starts_on_tonic?(voice)
      score *= HeadMusic::GOLDEN_RATIO_INVERSE
    end
    score
  end

  def self.annotations(voice)
    if fitness(voice) < 1
      start_position = Position.new(voice.composition, "1:1")
      end_position = start_position.start_of_next_measure
      [HeadMusic::Style::Annotation.new(voice, start_position, end_position, "Start on the tonic")]
    end
  end

  def self.starts_on_tonic?(voice)
    voice.notes &&
    voice.notes.first &&
    voice.composition &&
    voice.composition.key_signature &&
    voice.composition.key_signature.tonic_spelling == voice.notes.first.spelling
  end
end
