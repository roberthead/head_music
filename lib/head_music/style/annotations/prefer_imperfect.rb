module HeadMusic::Style::Annotations
end

class HeadMusic::Style::Annotations::PreferImperfect < HeadMusic::Style::Annotation
  MESSAGE = "Prefer imperfect harmonic intervals."

  def marks
    if ratio_of_perfect_intervals >= 0.5
      HeadMusic::Style::Mark.for_all(perfect_intervals.map(&:notes).flatten)
    end
  end

  private

  def ratio_of_perfect_intervals
    return 0 if downbeat_harmonic_intervals_in_middle.nil?
    perfect_intervals.length.to_f / downbeat_harmonic_intervals.length
  end

  def perfect_intervals
    downbeat_harmonic_intervals_in_middle.select { |interval| interval.perfect_consonance?(:two_part_harmony) }
  end

  def downbeat_harmonic_intervals_in_middle
    downbeat_harmonic_intervals[1..-2]
  end
end
