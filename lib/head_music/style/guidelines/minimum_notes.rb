# Module for style guidelines.
module HeadMusic::Style::Guidelines; end

# Flags a melody with fewer than the required number of notes.
# Configure the threshold with the factory, e.g. MinimumNotes.with(8).
class HeadMusic::Style::Guidelines::MinimumNotes < HeadMusic::Style::Guidelines::MinimumThreshold
  def marks
    placements.empty? ? no_placements_mark : deficiency_mark
  end

  def message
    "Write at least #{minimum.humanize} notes."
  end

  private

  def actual_count
    notes.length
  end
end
