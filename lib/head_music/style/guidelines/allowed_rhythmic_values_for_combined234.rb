# Module for style guidelines.
module HeadMusic::Style::Guidelines; end

# Validates that counterpoint notes use only half notes, quarter notes, and tied notes.
# No whole notes filling an entire bar from beat 1.
# Appropriate for combined second, third, and fourth species counterpoint.
class HeadMusic::Style::Guidelines::AllowedRhythmicValuesForCombined234 < HeadMusic::Style::Annotation
  MESSAGE = "Use only half notes, quarter notes, and tied notes. Avoid whole notes on beat 1."

  def marks
    violating_notes.map { |note| HeadMusic::Style::Mark.for(note) }
  end

  private

  def violating_notes
    notes.select { |note| whole_note_on_downbeat?(note) }
  end

  def whole_note_on_downbeat?(note)
    note.rhythmic_value.total_value >= 1.0 && note.position.count == 1
  end
end
