# Module for style guidelines.
module HeadMusic::Style::Guidelines; end

# A counterpoint guideline
class HeadMusic::Style::Guidelines::NoParallelPerfectWithSyncopation < HeadMusic::Style::Guidelines::NoParallelPerfect
  MESSAGE = "Avoid parallel perfect consonances between syncopated notes."

  private

  def analyzed_harmonic_intervals
    harmonic_intervals
  end
end
