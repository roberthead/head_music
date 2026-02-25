# Module for style guidelines.
module HeadMusic::Style::Guidelines; end

# Checks that the first bar contains exactly one whole note.
class HeadMusic::Style::Guidelines::FirstBarWholeNote < HeadMusic::Style::Annotation
  MESSAGE = "Begin with a whole note in the first bar."

  WHOLE = HeadMusic::Rudiment::RhythmicValue.get(:whole)

  def marks
    return unless notes.any?

    bar_notes = notes_in_first_bar
    return if bar_notes.length == 1 && bar_notes.first.rhythmic_value == WHOLE

    HeadMusic::Style::Mark.for_all(bar_notes.any? ? bar_notes : [first_note])
  end

  private

  def notes_in_first_bar
    notes.select { |note| note.position.bar_number == 1 }
  end
end
