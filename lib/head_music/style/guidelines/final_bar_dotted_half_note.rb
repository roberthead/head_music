# Module for style guidelines.
module HeadMusic::Style::Guidelines; end

# Checks that the final bar contains a single dotted half note.
class HeadMusic::Style::Guidelines::FinalBarDottedHalfNote < HeadMusic::Style::Annotation
  MESSAGE = "End with a single dotted half note in the final bar."

  DOTTED_HALF = HeadMusic::Rudiment::RhythmicValue.get(:dotted_half)

  def marks
    return unless notes.any?

    bar_notes = notes_in_final_bar
    return if bar_notes.length == 1 && bar_notes.first.rhythmic_value == DOTTED_HALF

    HeadMusic::Style::Mark.for_all(bar_notes.any? ? bar_notes : [last_note])
  end

  private

  def notes_in_final_bar
    notes.select { |note| note.position.bar_number == final_bar_number }
  end

  def final_bar_number
    last_note.position.bar_number
  end
end
