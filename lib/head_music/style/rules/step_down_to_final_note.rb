module HeadMusic::Style::Rules
end

class HeadMusic::Style::Rules::StepDownToFinalNote < HeadMusic::Style::Rule
  def self.fitness(voice)
    return 0 unless voice.notes.length >= 2
    fitness = 1
    melodic_interval = voice.melodic_intervals.last
    if !melodic_interval.step?
      fitness *= HeadMusic::GOLDEN_RATIO_INVERSE
    end
    if !melodic_interval.downward?
      fitness *= HeadMusic::GOLDEN_RATIO_INVERSE
    end
    fitness
  end

  def self.annotations(voice)
    if fitness(voice) < 1
      melodic_interval = voice.melodic_intervals.last
      if melodic_interval.nil?
        start_position = voice.placements.last ? voice.placements.last.position : '1:1'
        end_position = start_position.start_of_next_measure
      else
        start_position = voice.notes[-2].position
        end_position = voice.notes[-1].next_position
      end
      [HeadMusic::Style::Annotation.new(voice, start_position, end_position, "Step down to final note.")]
    end
  end
end
