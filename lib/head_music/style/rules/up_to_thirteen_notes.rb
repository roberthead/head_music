module HeadMusic::Style::Rules
end

class HeadMusic::Style::Rules::UpToThirteenNotes < HeadMusic::Style::Rule
  MAXIMUM_NOTES = 13

  def self.fitness(voice)
    score = 1
    overage = voice.notes.length - MAXIMUM_NOTES
    while overage > 0
      score *= HeadMusic::GOLDEN_RATIO_INVERSE
      overage -= 1
    end
    score
  end

  def self.annotations(voice)
    if fitness(voice) < 1
      start_position = voice.notes[MAXIMUM_NOTES].position
      end_position = voice.notes.last.next_position
      [HeadMusic::Style::Annotation.new(voice, start_position, end_position, "Remove notes until you have at most thirteen notes.")]
    end
  end
end
