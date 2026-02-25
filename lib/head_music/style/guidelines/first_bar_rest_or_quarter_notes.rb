# Module for style guidelines.
module HeadMusic::Style::Guidelines; end

# Checks that the first bar contains the expected number of quarter notes, or enters after a quarter rest.
class HeadMusic::Style::Guidelines::FirstBarRestOrQuarterNotes < HeadMusic::Style::Annotation
  MESSAGE = "Begin the first bar with quarter notes, or enter after a quarter rest."

  QUARTER = HeadMusic::Rudiment::RhythmicValue.get(:quarter)

  def marks
    return unless notes.any?
    return unless cantus_firmus&.notes&.any?

    bar_notes = notes_in_first_bar
    bar_rests = rests_in_first_bar
    return if full_quarter_notes?(bar_notes)
    return if rest_then_quarter_notes?(bar_notes, bar_rests)
    return if quarter_notes_after_downbeat?(bar_notes)

    HeadMusic::Style::Mark.for_all(bar_notes.any? ? bar_notes : [first_note])
  end

  private

  def notes_in_first_bar
    notes.select { |note| note.position.bar_number == 1 }
  end

  def rests_in_first_bar
    rests.select { |rest| rest.position.bar_number == 1 }
  end

  def full_quarter_notes?(bar_notes)
    bar_notes.length == expected_count && bar_notes.all? { |note| note.rhythmic_value == QUARTER }
  end

  def rest_then_quarter_notes?(bar_notes, bar_rests)
    bar_notes.length == expected_count - 1 &&
      bar_notes.all? { |note| note.rhythmic_value == QUARTER } &&
      bar_rests.length == 1 &&
      bar_rests.first.rhythmic_value == QUARTER
  end

  def quarter_notes_after_downbeat?(bar_notes)
    bar_notes.length == expected_count - 1 &&
      bar_notes.all? { |note| note.rhythmic_value == QUARTER } &&
      bar_notes.first.position.count > 1
  end

  def expected_count
    @expected_count ||= cantus_firmus_beats_per_bar
  end

  def cantus_firmus_beats_per_bar
    first_cf_note = cantus_firmus.notes.first
    return 4 unless first_cf_note

    (first_cf_note.rhythmic_value.total_value / QUARTER.total_value).to_i
  end
end
