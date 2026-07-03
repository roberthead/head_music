# Module for style guidelines.
module HeadMusic::Style::Guidelines; end

# Checks that each middle bar (not first or last) contains an exact number of
# notes of a given rhythmic value. Configurable via the `count:` and
# `rhythmic_value:` options; subclasses may set COUNT and RHYTHMIC_VALUE defaults.
class HeadMusic::Style::Guidelines::NoteCountPerBar < HeadMusic::Style::Annotation
  def marks
    return [] unless cantus_firmus&.notes&.any?

    middle_bars.filter_map { |bar_number| check_middle_bar(bar_number) }
  end

  def message
    "Use #{count.humanize} #{rhythmic_unit} #{(count == 1) ? "note" : "notes"} in each middle bar."
  end

  private

  def count
    options.fetch(:count) { self.class::COUNT }
  end

  def rhythmic_unit
    options.fetch(:rhythmic_value) { self.class::RHYTHMIC_VALUE }
  end

  def rhythmic_value
    @rhythmic_value ||= HeadMusic::Rudiment::RhythmicValue.get(rhythmic_unit)
  end

  def check_middle_bar(bar_number)
    bar_notes = notes_in_bar(bar_number)
    return if bar_notes.length == count && bar_notes.all? { |note| note.rhythmic_value == rhythmic_value }

    mark_bar(bar_number)
  end

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
