module HeadMusic::Style::Annotations
end

class HeadMusic::Style::Annotations::AvoidCrossingVoices < HeadMusic::Style::Annotation
  MESSAGE = "Avoid crossing voices. Maintain the high-low relationship between voices."

  def marks
    crossings.map do |crossing|
      HeadMusic::Style::Mark.for_all(crossing.notes)
    end
  end

  private

  def crossings
    harmonic_intervals.select do |harmonic_interval|
      harmonic_interval.pitch_orientation && harmonic_interval.pitch_orientation != predominant_pitch_orientation
    end
  end

  def predominant_pitch_orientation
    pitch_orientations
      .compact
      .group_by { |orientation| orientation }
      .max { |a, b| a[1].length <=> b[1].length }
      .first
  end

  def pitch_orientations
    harmonic_intervals.map(&:pitch_orientation).compact.uniq
  end
end
