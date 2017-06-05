module HeadMusic::Style::Annotations
end

class HeadMusic::Style::Annotations::AtLeastEightNotes < HeadMusic::Style::Annotation
  MINIMUM_NOTES = 8

  MESSAGE = "Write at least eight notes."

  def marks
    placements.empty? ? no_placements_mark : deficiency_mark
  end

  private

  def no_placements_mark
    HeadMusic::Style::Mark.new(
      HeadMusic::Position.new(composition, "1:1"),
      HeadMusic::Position.new(composition, "2:1"),
      fitness: 0
    )
  end

  def deficiency_mark
    if notes.length < MINIMUM_NOTES
      HeadMusic::Style::Mark.for_all(placements, fitness: notes.length.to_f / MINIMUM_NOTES)
    end
  end
end
