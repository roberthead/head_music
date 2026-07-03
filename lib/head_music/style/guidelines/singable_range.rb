# Module for style guidelines.
module HeadMusic::Style::Guidelines; end

# A voice shouldn't expend the range of a 10th.
# Configurable via the `maximum_range:` option (a diatonic interval number).
class HeadMusic::Style::Guidelines::SingableRange < HeadMusic::Style::Annotation
  MAXIMUM_RANGE = 10

  MESSAGE = "Limit melodic range to a 10th."

  def marks
    HeadMusic::Style::Mark.for_each(extremes, fitness: HeadMusic::PENALTY_FACTOR**overage) if overage.positive?
  end

  private

  def maximum_range
    options.fetch(:maximum_range) { self.class::MAXIMUM_RANGE }
  end

  def overage
    notes.any? ? [range.number - maximum_range, 0].max : 0
  end

  def extremes
    (highest_notes + lowest_notes).sort
  end
end
