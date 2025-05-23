# Module for style guidelines.
module HeadMusic::Style::Guidelines; end

# Ok, so a rule might be that after the first leap (after previous steps)
# one should normally move by step in the opposite direction
# unless another leap (in either direction) creates a consonant triad.
# - Brian
class HeadMusic::Style::Guidelines::RecoverLargeLeaps < HeadMusic::Style::Annotation
  MESSAGE = "Recover large leaps by step in the opposite direction."

  def marks
    melodic_note_pairs.each_cons(3).map do |note_pairs|
      if unrecovered_leap?(note_pairs[0], note_pairs[1], note_pairs[2])
        HeadMusic::Style::Mark.for_all(notes_in_note_pairs(note_pairs))
      end
    end.compact
  end

  private

  def notes_in_note_pairs(note_pairs)
    (note_pairs[0].notes + note_pairs[1].notes).uniq
  end

  def unrecovered_leap?(first_note_pair, second_note_pair, third_note_pair)
    first_note_pair.large_leap? &&
      !spelling_consonant_triad?(first_note_pair, second_note_pair, third_note_pair) &&
      (
        !direction_changed?(first_note_pair, second_note_pair) ||
        !second_note_pair.step?
      )
  end

  def spelling_consonant_triad?(first_note_pair, second_note_pair, third_note_pair)
    first_note_pair.spells_consonant_triad_with?(second_note_pair) ||
      second_note_pair.spells_consonant_triad_with?(third_note_pair)
  end

  def direction_changed?(first_note_pair, second_note_pair)
    first_note_pair.ascending? && second_note_pair.descending? ||
      first_note_pair.descending? && second_note_pair.ascending?
  end
end
