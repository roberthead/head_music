module HeadMusic::Style::Annotations
end

class HeadMusic::Style::Annotations::PermittedIntervals < HeadMusic::Style::Annotation
  PERMITTED_ASCENDING = %w[m2 M2 m3 M3 P4 P5 m6 P8]
  PERMITTED_DESCENDING = %w[m2 M2 m3 M3 P4 P5 P8]

  def message
    "Use only m2, M2, m3, M3, P4, P5, m6 (ascending), P8."
  end

  def marks
    melodic_intervals.reject { |interval| permitted?(interval) }.map do |unpermitted_interval|
      HeadMusic::Style::Mark.for_all([unpermitted_interval.first_note, unpermitted_interval.second_note])
    end
  end

  private

  def permitted?(melodic_interval)
    whitelist_for_interval(melodic_interval).include?(melodic_interval.shorthand)
  end

  def whitelist_for_interval(melodic_interval)
    melodic_interval.ascending? ? PERMITTED_ASCENDING : PERMITTED_DESCENDING
  end
end
