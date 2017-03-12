module HeadMusic::Style::Annotations
end

class HeadMusic::Style::Annotations::AtLeastEightNotes < HeadMusic::Style::Annotation
  MINIMUM_NOTES = 8

  def message
    "Write at least eight notes."
  end

  def marks
    placements.empty? ? no_placements_mark : deficiency_mark
  end

  private

  def no_placements_mark
    return Style::Mark.new(
      Position.new(composition, "1:1"),
      Position.new(composition, "2:1"),
      fitness: HeadMusic::PENALTY_FACTOR**MINIMUM_NOTES
    )
  end

  def deficiency_mark
    deficiency = [MINIMUM_NOTES - notes.length, 0].max
    if deficiency > 0
      Style::Mark.for_all(placements, fitness: HeadMusic::PENALTY_FACTOR**deficiency)
    end
  end
end
