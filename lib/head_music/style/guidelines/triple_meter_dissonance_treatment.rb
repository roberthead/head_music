# Module for style guidelines.
module HeadMusic::Style::Guidelines; end

# A counterpoint guideline for triple-meter dissonance treatment.
# Every dissonant note on beats 2 or 3 must be treated as a passing tone or neighbor tone.
class HeadMusic::Style::Guidelines::TripleMeterDissonanceTreatment < HeadMusic::Style::Guidelines::WeakBeatDissonanceTreatment
  MESSAGE = "Treat dissonances as passing tones or neighbor tones."

  private

  def recognized_figure?(note)
    super || neighbor_tone?(note)
  end

  # Neighbor tone: approached by step, left by step in the opposite direction.
  def neighbor_tone?(note)
    prev = preceding_note(note)
    foll = following_note(note)
    return false unless prev && foll

    approach = melodic_interval_between(prev, note)
    departure = melodic_interval_between(note, foll)

    approach.step? && departure.step? && approach.direction != departure.direction
  end
end
