# Module for style guidelines.
module HeadMusic::Style::Guidelines; end

# Checks that each middle bar contains exactly one whole note.
class HeadMusic::Style::Guidelines::OnePerBar < HeadMusic::Style::Guidelines::NoteCountPerBar
  MESSAGE = "Use one whole note in each middle bar."

  WHOLE = HeadMusic::Rudiment::RhythmicValue.get(:whole)

  private

  def check_middle_bar(bar_number)
    bar_notes = notes_in_bar(bar_number)
    return if bar_notes.length == 1 && bar_notes.first.rhythmic_value == WHOLE

    mark_bar(bar_number)
  end
end
