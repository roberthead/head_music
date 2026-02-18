# Module for style guidelines.
module HeadMusic::Style::Guidelines; end

# A counterpoint guideline
class HeadMusic::Style::Guidelines::FourToOne < HeadMusic::Style::Guidelines::NoteCountPerBar
  MESSAGE = "Use four quarter notes against each whole note in the cantus firmus."

  QUARTER = HeadMusic::Rudiment::RhythmicValue.get(:quarter)

  private

  def check_first_bar(bar_number)
    bar_notes = notes_in_bar(bar_number)
    bar_rests = rests_in_bar(bar_number)
    return if four_quarter_notes?(bar_notes)
    return if rest_then_three_quarter_notes?(bar_notes, bar_rests)
    return if three_quarter_notes_after_downbeat?(bar_notes)

    mark_bar(bar_number)
  end

  def check_middle_bar(bar_number)
    bar_notes = notes_in_bar(bar_number)
    return if four_quarter_notes?(bar_notes)

    mark_bar(bar_number)
  end

  def four_quarter_notes?(bar_notes)
    bar_notes.length == 4 && bar_notes.all? { |note| note.rhythmic_value == QUARTER }
  end

  def rest_then_three_quarter_notes?(bar_notes, bar_rests)
    bar_notes.length == 3 &&
      bar_notes.all? { |note| note.rhythmic_value == QUARTER } &&
      bar_rests.length == 1 &&
      bar_rests.first.rhythmic_value == QUARTER
  end

  def three_quarter_notes_after_downbeat?(bar_notes)
    bar_notes.length == 3 &&
      bar_notes.all? { |note| note.rhythmic_value == QUARTER } &&
      bar_notes.first.position.count > 1
  end
end
