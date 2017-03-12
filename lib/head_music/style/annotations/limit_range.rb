module HeadMusic::Style::Annotations
end

class HeadMusic::Style::Annotations::LimitRange < HeadMusic::Style::Annotation
  MAXIMUM_RANGE = 10

  def message
    'Limit melodic range to a 10th.'
  end

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
