# Module for style guidelines.
module HeadMusic::Style::Guidelines; end

# Ornamental dissonance figures in the graded voice, read against the cantus
# firmus. Expects the including class to provide #notes, #melodic_intervals,
# and #dissonant_with_cantus_at?, as every Guideline does.
module HeadMusic::Style::Guidelines::DissonanceFigureDetection
  private

  delegate :passing_tone?, :neighbor_tone?, :cambiata_dissonance?, :double_neighbor_member?,
    to: :dissonance_figures, private: true

  def dissonance_figures
    @dissonance_figures ||= HeadMusic::Style::Guideline::DissonanceFigures.new(
      notes: notes,
      melodic_intervals: melodic_intervals,
      dissonant: ->(note) { dissonant_with_cantus?(note) }
    )
  end

  def dissonant_with_cantus?(note)
    dissonant_with_cantus_at?(note.position)
  end
end
