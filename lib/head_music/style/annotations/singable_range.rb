module HeadMusic::Style::Annotations
end

class HeadMusic::Style::Annotations::SingableRange < HeadMusic::Style::Annotation
  MAXIMUM_RANGE = 10

  MESSAGE = 'Limit melodic range to a 10th.'

  def marks
    if overage > 0
      HeadMusic::Style::Mark.for_each(extremes, fitness: HeadMusic::PENALTY_FACTOR**overage)
    end
  end

  private

  def overage
    notes.length > 0 ? [range.number - MAXIMUM_RANGE, 0].max : 0
  end

  def extremes
    (highest_notes + lowest_notes).sort
  end
end
