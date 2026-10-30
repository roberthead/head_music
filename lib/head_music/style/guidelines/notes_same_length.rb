# Module for style guidelines.
module HeadMusic::Style::Guidelines; end

# A counterpoint guideline
class HeadMusic::Style::Guidelines::NotesSameLength < HeadMusic::Style::Guideline
  def marks
    HeadMusic::Style::Mark.for_each(all_wrong_length_notes)
  end

  def first_most_common_rhythmic_duration
    @first_most_common_rhythmic_duration ||= begin
      candidates = most_common_rhythmic_durations
      first_match = notes.detect { |note| candidates.include?(note.rhythmic_duration) }
      first_match&.rhythmic_duration
    end
  end

  def most_common_rhythmic_durations
    return [] if notes.empty?

    occurrences = occurrences_by_rhythmic_duration
    highest_count = occurrences.values.max
    occurrences.select { |_rhythmic_duration, count| count == highest_count }.keys
  end

  private

  def all_wrong_length_notes
    (wrong_length_notes + [wrong_length_last_note]).compact
  end

  def wrong_length_notes
    all_but_last_note.reject do |note|
      note.rhythmic_duration == first_most_common_rhythmic_duration
    end
  end

  def wrong_length_last_note
    last_note unless acceptable_duration_of_last_note?
  end

  def acceptable_duration_of_last_note?
    last_note.nil? ||
      [
        first_most_common_rhythmic_duration.total_value,
        first_most_common_rhythmic_duration.total_value * 2
      ].include?(last_note.rhythmic_duration.total_value)
  end

  def all_but_last_note
    notes[0..-2]
  end

  def occurrences_by_rhythmic_duration
    rhythmic_durations.tally
  end

  def rhythmic_durations
    notes.map(&:rhythmic_duration)
  end
end
