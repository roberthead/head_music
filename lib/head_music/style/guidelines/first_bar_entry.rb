# Module for style guidelines.
module HeadMusic::Style::Guidelines; end

# Base class for first-bar guidelines.
# Rules: (a) at least one note, (b) each note is the correct beat unit,
# (c) at most one rest, and only on the first beat.
class HeadMusic::Style::Guidelines::FirstBarEntry < HeadMusic::Style::Annotation
  def marks
    return unless notes.any?

    bar_notes = notes_in_first_bar
    bar_rests = rests_in_first_bar
    return if valid_first_bar?(bar_notes, bar_rests)

    HeadMusic::Style::Mark.for_all(bar_notes.any? ? bar_notes : [first_note])
  end

  private

  def expected_rhythmic_value
    raise NotImplementedError
  end

  def valid_first_bar?(bar_notes, bar_rests)
    bar_notes.any? &&
      all_correct_beat_unit?(bar_notes) &&
      valid_note_count?(bar_notes) &&
      valid_rests?(bar_rests)
  end

  def all_correct_beat_unit?(bar_notes)
    bar_notes.all? { |note| note.rhythmic_value == expected_rhythmic_value }
  end

  def valid_note_count?(bar_notes)
    expected = expected_notes_in_first_bar
    bar_notes.length == expected ||
      (bar_notes.length == expected - 1 && bar_notes.first.position.count > 1)
  end

  def expected_notes_in_first_bar
    meter = composition.meter_at(1)
    bar_duration = meter.count_unit.relative_value * meter.counts_per_bar
    (bar_duration / expected_rhythmic_value.total_value).round
  end

  def valid_rests?(bar_rests)
    bar_rests.empty? ||
      (bar_rests.length == 1 &&
        bar_rests.first.position.count == 1 &&
        bar_rests.first.rhythmic_value == expected_rhythmic_value)
  end

  def notes_in_first_bar
    notes.select { |note| note.position.bar_number == 1 }
  end

  def rests_in_first_bar
    rests.select { |rest| rest.position.bar_number == 1 }
  end
end
