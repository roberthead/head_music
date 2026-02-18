# Module for style guidelines.
module HeadMusic::Style::Guidelines; end

# Base class for guidelines that check note counts per bar against the cantus firmus.
class HeadMusic::Style::Guidelines::NoteCountPerBar < HeadMusic::Style::Annotation
  WHOLE = HeadMusic::Rudiment::RhythmicValue.get(:whole)

  def marks
    return [] unless cantus_firmus&.notes&.any?

    cf_notes = cantus_firmus.notes
    cf_notes.each_with_index.filter_map do |cf_note, index|
      bar_number = cf_note.position.bar_number
      if index == cf_notes.length - 1
        check_final_bar(bar_number)
      elsif index == 0
        check_first_bar(bar_number)
      else
        check_middle_bar(bar_number)
      end
    end
  end

  private

  def check_final_bar(bar_number)
    bar_notes = notes_in_bar(bar_number)
    return if one_whole_note?(bar_notes)

    mark_bar(bar_number)
  end

  def one_whole_note?(bar_notes)
    bar_notes.length == 1 && bar_notes.first.rhythmic_value == WHOLE
  end

  def notes_in_bar(bar_number)
    notes.select { |note| note.position.bar_number == bar_number }
  end

  def rests_in_bar(bar_number)
    rests.select { |rest| rest.position.bar_number == bar_number }
  end

  def mark_bar(bar_number)
    bar_placements = notes_in_bar(bar_number)
    if bar_placements.any?
      HeadMusic::Style::Mark.for_all(bar_placements)
    else
      cf_note = cantus_firmus.notes.detect { |note| note.position.bar_number == bar_number }
      HeadMusic::Style::Mark.for(cf_note) if cf_note
    end
  end
end
