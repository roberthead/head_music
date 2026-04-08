# Module for style guidelines.
module HeadMusic::Style::Guidelines; end

# A counterpoint guideline.
# Dissonant downbeats are permitted only when the counterpoint note is a
# properly tied-over suspension (i.e., it began before the current CF note).
class HeadMusic::Style::Guidelines::ConsonantDownbeats < HeadMusic::Style::Annotation
  MESSAGE = "Use consonant harmonic intervals on every downbeat (unless a tied suspension)."

  def marks
    dissonant_pairs.map do |dissonant_pair|
      HeadMusic::Style::Mark.for_all(dissonant_pair)
    end.flatten
  end

  private

  def dissonant_pairs
    non_suspension_dissonant_intervals.map(&:notes).compact
  end

  def non_suspension_dissonant_intervals
    dissonant_intervals.reject { |interval| tied_suspension?(interval) }
  end

  def dissonant_intervals
    downbeat_harmonic_intervals.select { |interval| interval.dissonance?(:two_part_harmony) }
  end

  def tied_suspension?(interval)
    cp_note = voice.note_at(interval.position)
    return false unless cp_note

    cp_note.position < interval.position
  end
end
