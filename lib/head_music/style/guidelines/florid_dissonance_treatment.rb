# Module for style guidelines.
module HeadMusic::Style::Guidelines; end

# Unified dissonance handling for mixed-species (florid) contexts. Judges
# each note at its attack: a dissonance attacked on a strong beat is a fault,
# and a weak-beat dissonance must be a passing tone, neighbor tone, nota
# cambiata, or double neighbor figure. A note held over into a dissonance
# starts on a weak beat and is consonant there, so it is never this
# guideline's concern; the suspension rule judges it.
class HeadMusic::Style::Guidelines::FloridDissonanceTreatment < HeadMusic::Style::Guideline
  include HeadMusic::Style::Guidelines::DissonanceFigureDetection

  def marks
    return [] unless cantus_firmus&.notes&.any?

    improperly_treated_notes.map { |note| HeadMusic::Style::Mark.for(note) }
  end

  private

  def improperly_treated_notes
    notes.select { |note| dissonant_with_cantus?(note) && !properly_treated?(note) }
  end

  def properly_treated?(note)
    return false if on_strong_beat?(note)

    passing_tone?(note) || neighbor_tone?(note) ||
      cambiata_dissonance?(note) || double_neighbor_member?(note)
  end

  def on_strong_beat?(note)
    cantus_firmus_positions.include?(note.position.to_s)
  end
end
