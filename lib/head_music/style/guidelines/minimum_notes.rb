# Module for style guidelines.
module HeadMusic::Style::Guidelines; end

# Flags a melody with fewer than the required number of notes.
# Configure the threshold with the factory, e.g. MinimumNotes.with(8).
class HeadMusic::Style::Guidelines::MinimumNotes < HeadMusic::Style::Guidelines::MinimumThreshold
  def marks
    voice_events.empty? ? no_voice_events_mark : deficiency_mark
  end

  private

  def actual_count
    notes.length
  end
end
