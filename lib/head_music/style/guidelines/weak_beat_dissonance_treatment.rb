# Module for style guidelines.
module HeadMusic::Style::Guidelines; end

# A counterpoint guideline
class HeadMusic::Style::Guidelines::WeakBeatDissonanceTreatment < HeadMusic::Style::Annotation
  include HeadMusic::Style::Guidelines::DissonanceFigureDetection

  MESSAGE = "Use only passing tones for dissonances on the weak beat."

  def marks
    return [] unless cantus_firmus&.notes&.any?

    dissonant_weak_beat_notes.reject { |note| recognized_figure?(note) }.map do |note|
      HeadMusic::Style::Mark.for(note)
    end
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
