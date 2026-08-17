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

  # The count comes from the configuration or the class default -- never from
  # config alone, which is empty for the unconfigured case.
  def self.template_values(config)
    count = config.fetch(:minimum)
    {count: count, number: HeadMusic::Style::Template.number_word(count)}
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
