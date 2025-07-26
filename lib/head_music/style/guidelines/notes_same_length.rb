# Module for style guidelines.
module HeadMusic::Style::Guidelines; end

# A counterpoint guideline
class HeadMusic::Style::Guidelines::NotesSameLength < HeadMusic::Style::Annotation
  MESSAGE = "Use consistent rhythmic unit."

  def marks
    HeadMusic::Style::Mark.for_each(all_wrong_length_notes)
  end

  def first_most_common_rhythmic_value
    @first_most_common_rhythmic_value ||= begin
      candidates = most_common_rhythmic_values
      first_match = notes.detect { |note| candidates.include?(note.rhythmic_value) }
      first_match&.rhythmic_value
    end
  end

  def most_common_rhythmic_values
    return [] if notes.empty?

    occurrences = occurrences_by_rhythmic_value
    highest_count = occurrences.values.max
    occurrences.select { |_rhythmic_value, count| count == highest_count }.keys
  end

  private

  def all_wrong_length_notes
    (wrong_length_notes + [wrong_length_last_note]).compact
  end

  def wrong_length_notes
    all_but_last_note.reject do |note|
      note.rhythmic_value == first_most_common_rhythmic_value
    end
  end

  def wrong_length_last_note
    last_note unless acceptable_duration_of_last_note?
  end

  def acceptable_duration_of_last_note?
    last_note.nil? ||
      [
        first_most_common_rhythmic_value.total_value,
        first_most_common_rhythmic_value.total_value * 2
      ].include?(last_note.rhythmic_value.total_value)
  end

  def all_but_last_note
    notes[0..-2]
  end

  def occurrences_by_rhythmic_value
    rhythmic_values.each_with_object(Hash.new(0)) { |value, hash| hash[value] += 1 }
  end

  def rhythmic_values
    notes.map(&:rhythmic_value)
  end
end
