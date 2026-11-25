# Module for style guidelines.
module HeadMusic::Style::Guidelines; end

# Unified dissonance handling for mixed-species (florid) contexts. Judges
# each note at its attack: a dissonance attacked on a downbeat is a fault,
# and any other must be a passing tone, a neighbor tone, or a quarter note in
# a placed nota cambiata or double neighbor. "Every note value is governed by
# the procedures of the species to which it belongs" (Salzer and Schachter,
# p. 103), so a dissonant half note may only pass, as in second species.
# A note held over into a dissonance is consonant where it is attacked, so it
# is never this guideline's concern; the suspension rule judges it.
class HeadMusic::Style::Guidelines::FloridDissonanceTreatment < HeadMusic::Style::Guideline
  include HeadMusic::Style::Guidelines::DissonanceFigureDetection
  include HeadMusic::Style::Guideline::FigurePlacement

  def marks
    return [] unless cantus_firmus&.notes&.any?

    HeadMusic::Style::Mark.for_each(improperly_treated_notes)
  end

  private

  def improperly_treated_notes
    notes.select { |note| dissonant_with_cantus?(note) && !properly_treated?(note) }
  end

  def properly_treated?(note)
    return false if downbeat_position?(note.position)
    return passing_tone?(note) if half_note_or_longer?(note)

    passing_tone?(note) || neighbor_tone?(note) || leaping_figure?(dissonance_figures, note, quarter_dissonances: true)
  end
end
