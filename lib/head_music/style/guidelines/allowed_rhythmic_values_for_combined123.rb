# Module for style guidelines.
module HeadMusic::Style::Guidelines; end

# Validates that counterpoint notes use only whole, half, or quarter note rhythmic values.
# Appropriate for combined first, second, and third species counterpoint.
class HeadMusic::Style::Guidelines::AllowedRhythmicValuesForCombined123 < HeadMusic::Style::Annotation
  MESSAGE = "Use only whole notes, half notes, and quarter notes."

  ALLOWED_TOTAL_VALUES = [1.0, 0.5, 0.25].freeze

  def marks
    violating_notes.map { |note| HeadMusic::Style::Mark.for(note) }
  end

  private

  def violating_notes
    notes.reject { |note| ALLOWED_TOTAL_VALUES.include?(note.rhythmic_value.total_value) }
  end
end
