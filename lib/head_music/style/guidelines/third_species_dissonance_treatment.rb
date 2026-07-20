# Module for style guidelines.
module HeadMusic::Style::Guidelines; end

# A counterpoint guideline for third-species dissonance treatment.
# Every dissonant note on beats 2, 3, or 4 must be treated as a passing tone,
# neighbor tone, nota cambiata, or double neighbor figure.
class HeadMusic::Style::Guidelines::ThirdSpeciesDissonanceTreatment < HeadMusic::Style::Guidelines::WeakBeatDissonanceTreatment
  MESSAGE = "Treat dissonances as passing tones, neighbor tones, cambiata, or double neighbor figures."

  private

  def recognized_figure?(note)
    super || neighbor_tone?(note) || cambiata_dissonance?(note) || double_neighbor_member?(note)
  end
end
