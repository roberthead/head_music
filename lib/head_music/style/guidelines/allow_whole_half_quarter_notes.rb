# Module for style guidelines.
module HeadMusic::Style::Guidelines; end

# Validates that counterpoint notes use only whole, half, or quarter note rhythmic values.
# Appropriate for counterpoint combining the first three species.
class HeadMusic::Style::Guidelines::AllowWholeHalfQuarterNotes < HeadMusic::Style::Guideline
  ALLOWED_TOTAL_VALUES = [1.0, 0.5, 0.25].freeze

  def marks
    violating_notes.map { |note| HeadMusic::Style::Mark.for(note) }
  end

  private

  def violating_notes
    notes.reject { |note| ALLOWED_TOTAL_VALUES.include?(note.rhythmic_value.total_value) }
  end
end
