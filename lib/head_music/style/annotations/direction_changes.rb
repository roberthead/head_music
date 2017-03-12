module HeadMusic::Style::Annotations
end

class HeadMusic::Style::Annotations::DirectionChanges < HeadMusic::Style::Annotation
  MAXIMUM_NOTES_PER_DIRECTION = 3

  def message
    "Balance ascending and descending motion."
  end

  def marks
    if overage > 0
      penalty_exponent = overage**0.5
      HeadMusic::Style::Mark.for_all(notes, fitness: PENALTY_FACTOR**penalty_exponent)
    end
  end

  private

  def overage
    return 0 if notes.length < 2
    [notes_per_direction - MAXIMUM_NOTES_PER_DIRECTION, 0].max
  end

  def notes_per_direction
    notes.length.to_f / (melodic_intervals_changing_direction.length + 1)
  end

  def melodic_intervals_changing_direction
    melodic_intervals[1..-1].select.with_index do |interval, i|
      previous_direction = melodic_intervals[i].direction
      interval.direction != previous_direction
    end
  end
end
