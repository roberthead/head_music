# frozen_string_literal: true

module HeadMusic::Style::Annotations
end

class HeadMusic::Style::Annotations::MostlyConjunct < HeadMusic::Style::Annotation
  MESSAGE = 'Use mostly conjunct motion.'

  MINIMUM_CONJUNCT_PORTION = HeadMusic::GOLDEN_RATIO_INVERSE**2
  # ~38%
  # Fux is 5/13 for lydian cantus firmus

  def marks
    marks_for_skips_and_leaps if conjunct_ratio < MINIMUM_CONJUNCT_PORTION
  end

  private

  def marks_for_skips_and_leaps
    melodic_intervals.map.with_index do |interval, i|
      HeadMusic::Style::Mark.for_all(notes[i..i + 1], fitness: HeadMusic::SMALL_PENALTY_FACTOR) unless interval.step?
    end.compact
  end

  def conjunct_ratio
    return 1 if melodic_intervals.empty?
    melodic_intervals.count(&:step?).to_f / melodic_intervals.length
  end
end
