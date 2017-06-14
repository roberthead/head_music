module HeadMusic::Style::Annotations
end

# Ok, so a rule might be that after the first leap (after previous steps)
# one should normally move by step in the opposite direction
# unless another leap (in either direction) creates a consonant triad.
# - Brian
class HeadMusic::Style::Annotations::SingleLargeLeaps < HeadMusic::Style::Annotation
  MESSAGE = "Recover leaps by step or opposite direction."

  def marks
    melodic_intervals.drop(1).to_a.map.with_index do |interval, i|
      previous_interval = melodic_intervals[i]
      if unrecovered_leap?(previous_interval, interval, melodic_intervals[i+2])
        HeadMusic::Style::Mark.for_all((previous_interval.notes + interval.notes).uniq)
      end
    end.compact
  end

  private

  def unrecovered_leap?(first_interval, second_interval, third_interval)
    return false unless first_interval.large_leap?
    return false if spelling_consonant_triad?(first_interval, second_interval, third_interval)
    return false if second_interval.step?
    !direction_changed?(first_interval, second_interval) || second_interval.large_leap?
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
