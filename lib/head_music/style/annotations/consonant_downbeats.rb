module HeadMusic::Style::Annotations
end

class HeadMusic::Style::Annotations::ConsonantDownbeats < HeadMusic::Style::Annotation
  MESSAGE = "Use consonant harmonic intervals."

  def marks
    dissonant_pairs.map do |dissonant_pair|
      HeadMusic::Style::Mark.for_all(dissonant_pair)
    end.flatten
  end

  private

  def dissonant_pairs
    dissonant_intervals.map(&:notes).reject(&:nil?)
  end

  def dissonant_intervals
    downbeat_harmonic_intervals.select { |interval| interval.dissonance?(:two_part_harmony) }
  end

  def downbeat_harmonic_intervals
    cantus_firmus.notes.map do |cantus_firmus_note|
      HarmonicInterval.new(cantus_firmus_note.voice, voice, cantus_firmus_note.position)
    end
  end
end
