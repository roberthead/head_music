# Module for style guidelines.
module HeadMusic::Style::Guidelines; end

# A counterpoint guideline
class HeadMusic::Style::Guidelines::ThreeToOne < HeadMusic::Style::Guidelines::NoteCountPerBar
  MESSAGE = "Use three quarter notes against each dotted half note in the cantus firmus."

  QUARTER = HeadMusic::Rudiment::RhythmicValue.get(:quarter)
  DOTTED_HALF = HeadMusic::Rudiment::RhythmicValue.get(:dotted_half)

  private

  def check_first_bar(bar_number)
    bar_notes = notes_in_bar(bar_number)
    bar_rests = rests_in_bar(bar_number)
    return if three_quarter_notes?(bar_notes)
    return if rest_then_two_quarter_notes?(bar_notes, bar_rests)
    return if two_quarter_notes_after_downbeat?(bar_notes)

    mark_bar(bar_number)
  end

  def check_middle_bar(bar_number)
    bar_notes = notes_in_bar(bar_number)
    return if three_quarter_notes?(bar_notes)

    mark_bar(bar_number)
  end

  def check_final_bar(bar_number)
    bar_notes = notes_in_bar(bar_number)
    return if one_dotted_half_note?(bar_notes)

    mark_bar(bar_number)
  end

  def three_quarter_notes?(bar_notes)
    bar_notes.length == 3 && bar_notes.all? { |note| note.rhythmic_value == QUARTER }
  end

  def rest_then_two_quarter_notes?(bar_notes, bar_rests)
    bar_notes.length == 2 &&
      bar_notes.all? { |note| note.rhythmic_value == QUARTER } &&
      bar_rests.length == 1 &&
      bar_rests.first.rhythmic_value == QUARTER
  end

  def two_quarter_notes_after_downbeat?(bar_notes)
    bar_notes.length == 2 &&
      bar_notes.all? { |note| note.rhythmic_value == QUARTER } &&
      bar_notes.first.position.count > 1
  end

  def one_dotted_half_note?(bar_notes)
    bar_notes.length == 1 && bar_notes.first.rhythmic_value == DOTTED_HALF
  end
end
