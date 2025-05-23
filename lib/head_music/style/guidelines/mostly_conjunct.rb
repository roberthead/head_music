# Module for style guidelines.
module HeadMusic::Style::Guidelines; end

# A counterpoint guideline
class HeadMusic::Style::Guidelines::MostlyConjunct < HeadMusic::Style::Annotation
  MESSAGE = "Use mostly conjunct motion."

  MINIMUM_CONJUNCT_PORTION = HeadMusic::GOLDEN_RATIO_INVERSE**2
  # ~38%
  # Fux is 5/13 for lydian cantus firmus

  def marks
    marks_for_skips_and_leaps if conjunct_ratio < MINIMUM_CONJUNCT_PORTION
  end

  private

  def marks_for_skips_and_leaps
    melodic_note_pairs
      .reject(&:step?)
      .map { |note_pair| HeadMusic::Style::Mark.for_all(note_pair.notes, fitness: HeadMusic::SMALL_PENALTY_FACTOR) }
  end

  def conjunct_ratio
    return 1 if melodic_note_pairs.empty?

    melodic_note_pairs.count(&:step?).to_f / melodic_note_pairs.length
  end
end
