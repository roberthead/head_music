# Module for style guidelines.
module HeadMusic::Style::Guidelines; end

# A counterpoint guideline
class HeadMusic::Style::Guidelines::WeakBeatDissonanceTreatment < HeadMusic::Style::Guideline
  include HeadMusic::Style::Guidelines::DissonanceFigureDetection

  def marks
    return [] unless cantus_firmus&.notes&.any?

    HeadMusic::Style::Mark.for_each(dissonant_weak_beat_notes.reject { |note| recognized_figure?(note) })
  end

  private

  def recognized_figure?(note)
    passing_tone?(note)
  end

  def dissonant_weak_beat_notes
    weak_beat_notes.select { |note| dissonant_with_cantus?(note) }
  end

  def weak_beat_notes
    notes.reject { |note| downbeat_position?(note.position) }
  end

  def downbeat_position?(position)
    cantus_firmus_positions.include?(position.to_s)
  end
end
