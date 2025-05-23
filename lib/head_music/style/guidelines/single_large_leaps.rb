# Module for style guidelines.
module HeadMusic::Style::Guidelines; end

# A counterpoint guideline
class HeadMusic::Style::Guidelines::SingleLargeLeaps < HeadMusic::Style::Guidelines::RecoverLargeLeaps
  MESSAGE = "Recover leaps by step, repetition, opposite direction, or spelling triad."

  private

  def unrecovered_leap?(first_note_pair, second_note_pair, third_note_pair)
    return false unless first_note_pair.large_leap?
    return false if spelling_consonant_triad?(first_note_pair, second_note_pair, third_note_pair)
    return false if second_note_pair.step?
    return false if second_note_pair.repetition?

    !direction_changed?(first_note_pair, second_note_pair) && second_note_pair.leap?
  end
end
