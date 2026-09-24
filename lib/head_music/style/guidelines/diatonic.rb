# Module for style guidelines.
module HeadMusic::Style::Guidelines; end

# A counterpoint guideline. Exempts the accidentals the modes require, as
# Salzer and Schachter give them (pp. 9-10 and 20).
class HeadMusic::Style::Guidelines::Diatonic < HeadMusic::Style::Guideline
  def marks
    HeadMusic::Style::Mark.for_each(notes_not_in_key.reject { |note| modal_accidental?(note) })
  end

  protected

  # Score by the rate of out-of-key notes rather than the raw count,
  # so fitness is invariant to melody length.
  def fitness_denominator
    notes.length
  end

  private

  def modal_accidental?(note)
    raised_seventh_to_tonic?(note) ||
      raised_sixth_to_raised_seventh?(note) ||
      lowered_fourth_in_lydian?(note) ||
      lowered_in_descent?(note)
  end

  # "The seventh step is raised" where it functions as a leading tone.
  def raised_seventh_to_tonic?(note)
    following = following_note(note)
    altered?(note, 7, 1) && following &&
      following.spelling == tonic_spelling &&
      HeadMusic::Analysis::MelodicInterval.new(note, following).step? &&
      following.pitch > note.pitch
  end

  # "If the leading tone is preceded by the sixth degree of the scale, that
  # tone must also be raised."
  def raised_sixth_to_raised_seventh?(note)
    following = following_note(note)
    altered?(note, 6, 1) && following && altered?(following, 7, 1)
  end

  # "The Lydian mode (on F) regularly employs B flat."
  def lowered_fourth_in_lydian?(note)
    mode == :lydian && altered?(note, 4, -1)
  end

  # Dorian's sixth step "occurs in variable form", flat in descent, as
  # mixolydian's B flat does.
  def lowered_in_descent?(note)
    return false unless variable_step_lowered?(note)

    preceding = preceding_note(note)
    following = following_note(note)
    preceding && following && preceding.pitch > note.pitch && following.pitch < note.pitch
  end

  def variable_step_lowered?(note)
    case mode
    when :dorian then altered?(note, 6, -1)
    when :mixolydian then altered?(note, 3, -1)
    else false
    end
  end

  def altered?(note, degree, semitones)
    scale_degree = HeadMusic::Rudiment::ScaleDegree.new(key_signature, note.pitch.spelling)
    scale_degree.degree == degree && scale_degree.alteration_semitones == semitones
  end

  def mode
    key_signature.scale_type.name
  end
end
