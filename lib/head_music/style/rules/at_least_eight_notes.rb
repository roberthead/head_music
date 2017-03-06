module HeadMusic::Style::Rules
end

class HeadMusic::Style::Rules::AtLeastEightNotes < HeadMusic::Style::Rule
  MINIMUM_NOTES = 8

  def self.fitness(voice)
    return 0 if voice.notes.length == 0
    deficiency = MINIMUM_NOTES - voice.notes.length
    deficiency > 0 ? HeadMusic::GOLDEN_RATIO_INVERSE**deficiency : 1
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
      [HeadMusic::Style::Annotation.new(voice, start_position, end_position, "Add notes until you have at least eight notes.")]
    end
  end
end
