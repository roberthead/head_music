# Module for style guidelines.
module HeadMusic::Style::Guidelines; end

# A counterpoint guideline
class HeadMusic::Style::Guidelines::FourToOne < HeadMusic::Style::Annotation
  MESSAGE = "Use four quarter notes against each whole note in the cantus firmus."

  QUARTER = HeadMusic::Rudiment::RhythmicValue.get(:quarter)
  WHOLE = HeadMusic::Rudiment::RhythmicValue.get(:whole)

  def marks
    return [] unless cantus_firmus&.notes&.any?

    cantus_firmus.notes.each_with_index.filter_map do |cf_note, index|
      bar_number = cf_note.position.bar_number
      if index == cantus_firmus.notes.length - 1
        check_final_bar(bar_number)
      elsif index == 0
        check_first_bar(bar_number)
      else
        check_middle_bar(bar_number)
      end
    end
  end

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

  def check_final_bar(bar_number)
    bar_notes = notes_in_bar(bar_number)
    return if one_whole_note?(bar_notes)

    mark_bar(bar_number)
  end

  def four_quarter_notes?(bar_notes)
    bar_notes.length == 4 && bar_notes.all? { |n| n.rhythmic_value == QUARTER }
  end

  def one_whole_note?(bar_notes)
    bar_notes.length == 1 && bar_notes.first.rhythmic_value == WHOLE
  end

  def rest_then_three_quarter_notes?(bar_notes, bar_rests)
    bar_notes.length == 3 &&
      bar_notes.all? { |n| n.rhythmic_value == QUARTER } &&
      bar_rests.length == 1 &&
      bar_rests.first.rhythmic_value == QUARTER
  end

  def three_quarter_notes_after_downbeat?(bar_notes)
    bar_notes.length == 3 &&
      bar_notes.all? { |n| n.rhythmic_value == QUARTER } &&
      bar_notes.first.position.count > 1
  end

  def notes_in_bar(bar_number)
    notes.select { |n| n.position.bar_number == bar_number }
  end

  def rests_in_bar(bar_number)
    rests.select { |r| r.position.bar_number == bar_number }
  end

  def mark_bar(bar_number)
    bar_placements = notes_in_bar(bar_number)
    if bar_placements.any?
      HeadMusic::Style::Mark.for_all(bar_placements)
    else
      cf_note = cantus_firmus.notes.detect { |n| n.position.bar_number == bar_number }
      HeadMusic::Style::Mark.for(cf_note) if cf_note
    end
  end
end
