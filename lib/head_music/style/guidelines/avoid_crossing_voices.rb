# Module for style guidelines.
module HeadMusic::Style::Guidelines; end

# A counterpoint guideline
class HeadMusic::Style::Guidelines::AvoidCrossingVoices < HeadMusic::Style::Guideline
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

  # A tie goes to the orientation heard first.
  def predominant_pitch_orientation
    @predominant_pitch_orientation ||= pitch_orientations.tally.max_by { |_, count| count }.first
  end

  def pitch_orientations
    harmonic_intervals.map(&:pitch_orientation).compact
  end
end
