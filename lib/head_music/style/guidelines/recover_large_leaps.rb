# frozen_string_literal: true

# Module for style guidelines.
module HeadMusic::Style::Guidelines; end

# Ok, so a rule might be that after the first leap (after previous steps)
# one should normally move by step in the opposite direction
# unless another leap (in either direction) creates a consonant triad.
# - Brian
class HeadMusic::Style::Guidelines::RecoverLargeLeaps < HeadMusic::Style::Annotation
  MESSAGE = "Recover large leaps by step in the opposite direction."

  def marks
    melodic_intervals.each_cons(3).map do |intervals|
      if unrecovered_leap?(intervals[0], intervals[1], intervals[2])
        HeadMusic::Style::Mark.for_all(notes_in_intervals(intervals))
      end
    end.compact
  end

  private

  def notes_in_intervals(intervals)
    (intervals[0].notes + intervals[1].notes).uniq
  end

  def unrecovered_leap?(first_interval, second_interval, third_interval)
    first_interval.large_leap? &&
      !spelling_consonant_triad?(first_interval, second_interval, third_interval) &&
      (
        !direction_changed?(first_interval, second_interval) ||
        !second_interval.step?
      )
  end

  def spelling_consonant_triad?(first_interval, second_interval, third_interval)
    first_interval.spells_consonant_triad_with?(second_interval) ||
      second_interval.spells_consonant_triad_with?(third_interval)
  end

  def direction_changed?(first_interval, second_interval)
    first_interval.ascending? && second_interval.descending? ||
      first_interval.descending? && second_interval.ascending?
  end
end
