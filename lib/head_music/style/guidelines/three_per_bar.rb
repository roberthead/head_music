# Module for style guidelines.
module HeadMusic::Style::Guidelines; end

# Checks that each middle bar contains exactly three quarter notes.
class HeadMusic::Style::Guidelines::ThreePerBar < HeadMusic::Style::Guidelines::NoteCountPerBar
  MESSAGE = "Use three quarter notes in each middle bar."

  QUARTER = HeadMusic::Rudiment::RhythmicValue.get(:quarter)

  private

  def check_middle_bar(bar_number)
    bar_notes = notes_in_bar(bar_number)
    return if bar_notes.length == 3 && bar_notes.all? { |note| note.rhythmic_value == QUARTER }

    mark_bar(bar_number)
  end
end
