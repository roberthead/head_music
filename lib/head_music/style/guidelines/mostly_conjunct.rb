# Module for style guidelines.
module HeadMusic::Style::Guidelines; end

# A counterpoint guideline. Configurable via the `minimum_conjunct_portion:`
# option (the minimum fraction of melodic motion that must be stepwise).
class HeadMusic::Style::Guidelines::MostlyConjunct < HeadMusic::Style::Guideline
  strength :weak, because: "the threshold is a proportion, so this measures the character of a line rather than finding a fault in it"

  MINIMUM_CONJUNCT_PORTION = HeadMusic::GOLDEN_RATIO_INVERSE**2
  # ~38%
  # Fux is 5/13 for lydian cantus firmus

  def marks
    marks_for_skips_and_leaps if conjunct_ratio < minimum_conjunct_portion
  end

  private

  def minimum_conjunct_portion
    options.fetch(:minimum_conjunct_portion) { self.class::MINIMUM_CONJUNCT_PORTION }
  end

  # Marked at the default rather than the small penalty: this guideline is soft
  # all the way through and says so with strength :weak, which is what a rubric
  # weight is for. The small penalty said it inside the item's own fitness, where
  # it also decided how fast the item collapsed on repeats -- and every skip and
  # leap is marked once this trips, so six leaps used to land at 0.786^6 = 0.236
  # and now land at 0.618^6 = 0.056.
  def marks_for_skips_and_leaps
    melodic_note_pairs
      .reject(&:step?)
      .map { |note_pair| HeadMusic::Style::Mark.for_all(note_pair.notes) }
  end

  def conjunct_ratio
    return 1 if melodic_note_pairs.empty?

    melodic_note_pairs.count(&:step?).to_f / melodic_note_pairs.length
  end
end
