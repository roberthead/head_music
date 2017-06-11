module HeadMusic::Style::Annotations
end

# Ok, so a rule might be that after the first leap (after previous steps)
# one should normally move by step in the opposite direction
# unless another leap (in either direction) creates a consonant triad.
# - Brian
class HeadMusic::Style::Annotations::RecoverLargeLeaps < HeadMusic::Style::Annotation
  MESSAGE = "Recover leaps by step in the opposite direction."

  def marks
    melodic_intervals.drop(1).to_a.map.with_index do |interval, i|
      previous_interval = melodic_intervals[i]
      if unrecovered_leap?(previous_interval, interval)
        HeadMusic::Style::Mark.for_all((previous_interval.notes + interval.notes).uniq)
      end
    end.compact
  end

  private

  def unrecovered_leap?(first_interval, second_interval)
    first_interval.large_leap? &&
    !spelling_consonant_triad?(first_interval, second_interval) &&
    (
      !direction_changed?(first_interval, second_interval) ||
      !second_interval.step?
    )
  end

  def spelling_consonant_triad?(first_interval, second_interval)
    return false if first_interval.step? || second_interval.step?
    pitches = (first_interval.pitches + second_interval.pitches).uniq
    return false if pitches.length < 3
    HeadMusic::Chord.new(pitches).consonant_triad?
  end

  def direction_changed?(first_interval, second_interval)
    first_interval.ascending? && second_interval.descending? ||
      first_interval.descending? && second_interval.ascending?
  end
end
