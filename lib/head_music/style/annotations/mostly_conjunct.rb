module HeadMusic::Style::Annotations
end

class HeadMusic::Style::Annotations::MostlyConjunct < HeadMusic::Style::Annotation
  MESSAGE = "Use mostly conjunct motion."

  def marks
    marks_for_skips_and_leaps if conjunct_ratio <= 0.5
  end

  private

  def marks_for_skips_and_leaps
    melodic_intervals.map.with_index do |interval, i|
      HeadMusic::Style::Mark.for_all(notes[i..i+1], fitness: HeadMusic::SMALL_PENALTY_FACTOR) unless interval.step?
    end.reject(&:nil?)
  end

  def conjunct_ratio
    return 1 if melodic_intervals.empty?
    steps = melodic_intervals.count { |interval| interval.step? }
    steps.to_f / melodic_intervals.length
  end
end
