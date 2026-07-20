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
end
