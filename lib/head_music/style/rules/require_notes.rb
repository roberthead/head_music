module HeadMusic::Style::Rules
end

class HeadMusic::Style::Rules::RequireNotes < HeadMusic::Style::Rule
  MINIMUM_NOTES = 7

  def self.fitness(voice)
    [MINIMUM_NOTES, voice.placements.select(&:note?).length].min / MINIMUM_NOTES.to_f
  end

  def self.annotations(voice)
    if fitness(voice) < 1
      if voice.notes && voice.notes.last
        start_position = voice.notes.last.position
        end_position = voice.placements.last.position.start_of_next_measure
      else
        start_position = HeadMusic::Position.new(voice.composition, "1:1")
        end_position = HeadMusic::Position.new(voice.composition, "2:1")
      end
      [HeadMusic::Style::Annotation.new(voice, start_position, end_position, "Add more notes")]
    end
  end
end
