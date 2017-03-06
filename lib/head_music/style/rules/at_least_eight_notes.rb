module HeadMusic::Style::Rules
end

class HeadMusic::Style::Rules::AtLeastEightNotes < HeadMusic::Style::Rule
  MINIMUM_NOTES = 8

  def self.analyze(voice)
    fitness = fitness(voice)
    mark = mark(voice)
    message = "Add notes until you have at least eight notes." if fitness < 1
    HeadMusic::Style::Annotation.new(subject: voice, fitness: fitness, marks: mark, message: message)
  end

  def self.fitness(voice)
    deficiency = MINIMUM_NOTES - voice.notes.length
    deficiency > 0 ? HeadMusic::GOLDEN_RATIO_INVERSE**deficiency : 1
  end

  def self.mark(voice)
    if voice.placements.empty?
      Style::Mark.new(Position.new(voice.composition, "1:1"), Position.new(voice.composition, "2:1"))
    else
      Style::Mark.for_all(voice.placements)
    end
  end
end
