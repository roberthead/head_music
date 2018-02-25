# frozen_string_literal: true

# Module for Annotations.
module HeadMusic::Style::Annotations; end

# A counterpoint guideline
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
    melodic_intervals.
      reject(&:step?).
      map { |interval| HeadMusic::Style::Mark.for_all(interval.notes, fitness: HeadMusic::SMALL_PENALTY_FACTOR) }
  end

  def conjunct_ratio
    return 1 if melodic_intervals.empty?
    melodic_intervals.count(&:step?).to_f / melodic_intervals.length
  end
end
