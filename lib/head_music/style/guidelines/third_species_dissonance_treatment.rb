# Module for style guidelines.
module HeadMusic::Style::Guidelines; end

# A counterpoint guideline for third-species dissonance treatment.
# Every dissonant note on beats 2, 3, or 4 must be treated as a passing tone,
# neighbor tone, nota cambiata, or double neighbor figure. The last two count
# only where they are placed in the bar; their note values are the melody
# guide's to judge.
class HeadMusic::Style::Guidelines::ThirdSpeciesDissonanceTreatment < HeadMusic::Style::Guidelines::WeakBeatDissonanceTreatment
  include HeadMusic::Style::Guideline::FigurePlacement

  private

  def recognized_figure?(note)
    super || neighbor_tone?(note) || leaping_figure?(dissonance_figures, note, quarter_dissonances: false)
  end
end
