# Module for style guidelines.
module HeadMusic::Style::Guidelines; end

# Checks that the final bar contains a single note that fills the entire measure.
class HeadMusic::Style::Guidelines::NoteFillsFinalBar < HeadMusic::Style::Annotation
  MESSAGE = "End with a single note that fills the final bar."

  def marks
    return unless notes.any?

    bar_notes = notes_in_final_bar
    return if bar_notes.length == 1 && fills_bar?(bar_notes.first)

    HeadMusic::Style::Mark.for_all(bar_notes.any? ? bar_notes : [last_note])
  end

  private

  def notes_in_final_bar
    notes.select { |note| note.position.bar_number == final_bar_number }
  end

  def final_bar_number
    last_note.position.bar_number
  end

  def fills_bar?(note)
    note.rhythmic_value.total_value == bar_duration
  end

  def bar_duration
    meter = composition.meter_at(final_bar_number)
    meter.count_unit.relative_value * meter.counts_per_bar
  end
end
