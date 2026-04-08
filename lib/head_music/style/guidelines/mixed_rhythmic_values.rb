# Module for style guidelines.
module HeadMusic::Style::Guidelines; end

# Checks that the voice uses at least 3 different rhythmic value durations.
# Florid counterpoint requires a genuine mixture of species textures.
class HeadMusic::Style::Guidelines::MixedRhythmicValues < HeadMusic::Style::Annotation
  MESSAGE = "Use at least three different rhythmic values for a truly florid line."

  def marks
    return [] if notes.length < 2
    return [] if distinct_durations_count >= 3

    [HeadMusic::Style::Mark.for(notes.first)]
  end

  private

  def distinct_durations_count
    notes.map { |note| note.rhythmic_value.total_value }.uniq.length
  end
end
