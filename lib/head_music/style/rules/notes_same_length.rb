module HeadMusic::Style::Rules
end

class HeadMusic::Style::Rules::NotesSameLength < HeadMusic::Style::Rule
  def self.fitness(voice)
    score = 1
    if voice.notes.length > 1
      distinct_values = voice.notes[0..-2].map(&:rhythmic_value).uniq.length
      score *= HeadMusic::GOLDEN_RATIO_INVERSE**(distinct_values-1)
    end
    score
  end

  def self.annotations(voice)
    if fitness(voice) < 1
      start_position = voice.notes.length > 0 ? voice.notes.first.position : '1:1'
      end_position = voice.notes.length > 0 ? voice.notes.last.next_position : '2:1'
      [HeadMusic::Style::Annotation.new(voice, start_position, end_position, "Use consistent rhythmic unit.")]
    end
  end
end
