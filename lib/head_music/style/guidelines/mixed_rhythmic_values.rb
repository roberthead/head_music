# Module for style guidelines.
module HeadMusic::Style::Guidelines; end

# Checks that the voice uses at least 2 different rhythmic value durations.
# For full fifth species counterpoint.
class HeadMusic::Style::Guidelines::MixedRhythmicValues < HeadMusic::Style::Annotation
  MESSAGE = "Use a variety of rhythmic values for an expressive florid line."

  def marks
    return [] if notes.length < 2
    return [] if distinct_durations_count >= 2

    [HeadMusic::Style::Mark.for(notes.first)]
  end

  private

  def distinct_durations_count
    notes.map { |note| note.rhythmic_value.total_value }.uniq.length
  end
end
