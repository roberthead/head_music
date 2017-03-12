module HeadMusic::Style::Annotations
end

class HeadMusic::Style::Annotations::MostlyConjunct < HeadMusic::Style::Annotation
  def message
    "Use only notes in the key signature."
  end

  def marks
    if conjunct_intervals_per_interval < 0.5
      fitness = conjunct_intervals_per_interval < 0.25 ? HeadMusic::PENALTY_FACTOR : HeadMusic::SMALL_PENALTY_FACTOR
      melodic_intervals.map.with_index do |interval, i|
        HeadMusic::Style::Mark.for_all(notes[i..i+1]) if !interval.step?
      end
    end
  end

  private

  def conjunct_intervals_per_interval
    intervals = melodic_intervals
    steps = melodic_intervals.count { |interval| interval.step? }
    steps.to_f / intervals.length
  end
end
