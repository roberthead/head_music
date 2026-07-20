# Module for style guidelines.
module HeadMusic::Style::Guidelines; end

# Flags a melody with fewer than the required number of moving melodic intervals.
# Repeated-note pairs don't count as motion, so an all-repeated-note line gates to 0.
# Configure the threshold with the factory, e.g. MinimumMelodicIntervals.with(2).
class HeadMusic::Style::Guidelines::MinimumMelodicIntervals < HeadMusic::Style::Guidelines::MinimumThreshold
  def marks
    return no_motion_mark if moving_intervals.empty?

    deficiency_mark
  end

  def message
    "Write at least #{minimum.humanize} melodic intervals."
  end

  private

  def moving_intervals
    melodic_intervals.select(&:moving?)
  end

  def no_motion_mark
    return no_placements_mark if placements.empty?

    HeadMusic::Style::Mark.for_all(placements, fitness: 0)
  end

  def actual_count
    moving_intervals.length
  end
end
