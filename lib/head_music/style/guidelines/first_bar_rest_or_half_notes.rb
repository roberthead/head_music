# Module for style guidelines.
module HeadMusic::Style::Guidelines; end

# Checks that the first bar contains two half notes, or a half rest followed by a half note.
class HeadMusic::Style::Guidelines::FirstBarRestOrHalfNotes < HeadMusic::Style::Annotation
  MESSAGE = "Begin the first bar with two half notes, or enter with a half note after a half rest."

  HALF = HeadMusic::Rudiment::RhythmicValue.get(:half)

  def marks
    return unless notes.any?

    bar_notes = notes_in_first_bar
    bar_rests = rests_in_first_bar
    return if two_half_notes?(bar_notes)
    return if rest_then_half_note?(bar_notes, bar_rests)
    return if single_half_note_after_downbeat?(bar_notes)

    HeadMusic::Style::Mark.for_all(bar_notes.any? ? bar_notes : [first_note])
  end

  private

  def notes_in_first_bar
    notes.select { |note| note.position.bar_number == 1 }
  end

  def rests_in_first_bar
    rests.select { |rest| rest.position.bar_number == 1 }
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
    bar_notes.length == 1 &&
      bar_notes.first.rhythmic_value == HALF &&
      bar_notes.first.position.count > 1
  end
end
