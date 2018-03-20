# frozen_string_literal: true

# Module for style guidelines.
module HeadMusic::Style::Guidelines; end

# A voice shouldn't expend the range of a 10th.
class HeadMusic::Style::Guidelines::SingableRange < HeadMusic::Style::Annotation
  MAXIMUM_RANGE = 10

  MESSAGE = 'Limit melodic range to a 10th.'

  def marks
    HeadMusic::Style::Mark.for_each(extremes, fitness: HeadMusic::PENALTY_FACTOR**overage) if overage.positive?
  end

  private

  def overage
    notes.any? ? [range.number - MAXIMUM_RANGE, 0].max : 0
  end

  def extremes
    (highest_notes + lowest_notes).sort
  end
end
