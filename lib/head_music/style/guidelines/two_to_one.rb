# Module for style guidelines.
module HeadMusic::Style::Guidelines; end

# A counterpoint guideline
class HeadMusic::Style::Guidelines::TwoToOne < HeadMusic::Style::Guidelines::NoteCountPerBar
  MESSAGE = "Use two half notes against each whole note in the cantus firmus."

  HALF = HeadMusic::Rudiment::RhythmicValue.get(:half)

  private

  def check_first_bar(bar_number)
    bar_notes = notes_in_bar(bar_number)
    bar_rests = rests_in_bar(bar_number)
    return if two_half_notes?(bar_notes)
    return if rest_then_half_note?(bar_notes, bar_rests)
    return if single_half_note_after_downbeat?(bar_notes)

    mark_bar(bar_number)
  end

  def check_middle_bar(bar_number)
    bar_notes = notes_in_bar(bar_number)
    return if two_half_notes?(bar_notes)

    mark_bar(bar_number)
  end

  def two_half_notes?(bar_notes)
    bar_notes.length == 2 && bar_notes.all? { |note| note.rhythmic_value == HALF }
  end

  def rest_then_half_note?(bar_notes, bar_rests)
    bar_notes.length == 1 &&
      bar_notes.first.rhythmic_value == HALF &&
      bar_rests.length == 1 &&
      bar_rests.first.rhythmic_value == HALF
  end

  def single_half_note_after_downbeat?(bar_notes)
    first_note = bar_notes.first
    bar_notes.length == 1 &&
      first_note.rhythmic_value == HALF &&
      first_note.position.count > 1
  end
end
