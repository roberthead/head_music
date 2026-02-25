# Module for style guidelines.
module HeadMusic::Style::Guidelines; end

# Base class for guidelines that check note counts in middle bars (not first or last).
class HeadMusic::Style::Guidelines::NoteCountPerBar < HeadMusic::Style::Annotation
  def marks
    return [] unless cantus_firmus&.notes&.any?

    middle_bars.filter_map { |bar_number| check_middle_bar(bar_number) }
  end

  private

  def middle_bars
    cf_notes = cantus_firmus.notes
    return [] if cf_notes.length <= 2

    cf_notes[1..-2].map { |note| note.position.bar_number }
  end

  def notes_in_bar(bar_number)
    notes.select { |note| note.position.bar_number == bar_number }
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
