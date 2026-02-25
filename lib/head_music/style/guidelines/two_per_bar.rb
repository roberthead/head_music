# Module for style guidelines.
module HeadMusic::Style::Guidelines; end

# Checks that each middle bar contains exactly two half notes.
class HeadMusic::Style::Guidelines::TwoPerBar < HeadMusic::Style::Guidelines::NoteCountPerBar
  MESSAGE = "Use two half notes in each middle bar."

  HALF = HeadMusic::Rudiment::RhythmicValue.get(:half)

  private

  def check_middle_bar(bar_number)
    bar_notes = notes_in_bar(bar_number)
    return if bar_notes.length == 2 && bar_notes.all? { |note| note.rhythmic_value == HALF }

    mark_bar(bar_number)
  end
end
