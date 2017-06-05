module HeadMusic::Style::Annotations
end

class HeadMusic::Style::Annotations::NotesSameLength < HeadMusic::Style::Annotation
  MESSAGE = 'Use consistent rhythmic unit.'

  def marks
    preferred_value = first_most_common_rhythmic_value
    wrong_length_notes = all_but_last_note.select { |note| note.rhythmic_value != preferred_value }
    HeadMusic::Style::Mark.for_each(wrong_length_notes)
  end

  private

  def all_but_last_note
    notes[0..-2]
  end

  def distinct_values
    all_but_last_note.map(&:rhythmic_value).uniq.length
  end

  def first_most_common_rhythmic_value
    candidates = most_common_rhythmic_values
    first_match = notes.detect { |note| candidates.include?(note.rhythmic_value) }
    first_match ? first_match.rhythmic_value : nil
  end

  def most_common_rhythmic_values
    return [] if notes.empty?
    occurrences = occurrences_by_rhythmic_value
    highest_count = occurrences.values.sort.last
    occurrences.select { |_rhythmic_value, count| count == highest_count }.keys
  end

  def occurrences_by_rhythmic_value
    rhythmic_values.inject(Hash.new(0)) { |hash, value| hash[value] += 1; hash }
  end

  def rhythmic_values
    notes.map(&:rhythmic_value)
  end
end
