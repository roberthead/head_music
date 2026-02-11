# Module for style guidelines.
module HeadMusic::Style::Guidelines; end

# A counterpoint guideline
class HeadMusic::Style::Guidelines::NoStrongBeatUnisons < HeadMusic::Style::Annotation
  MESSAGE = "Avoid unisons on strong beats except at the beginning and end."

  def marks
    interior_downbeat_unisons.map do |interval|
      HeadMusic::Style::Mark.for_all(interval.notes)
    end
  end

  private

  def interior_downbeat_unisons
    interior_downbeat_intervals.select { |interval| interval.perfect_consonance? && interval.unison? }
  end

  def interior_downbeat_intervals
    return [] if downbeat_harmonic_intervals.length < 3

    downbeat_harmonic_intervals[1..-2]
  end
end
