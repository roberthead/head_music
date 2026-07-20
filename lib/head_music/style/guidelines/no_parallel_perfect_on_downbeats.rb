# Module for style guidelines.
module HeadMusic::Style::Guidelines; end

# A counterpoint guideline
class HeadMusic::Style::Guidelines::NoParallelPerfectOnDownbeats < HeadMusic::Style::Guidelines::NoParallelPerfect
  MESSAGE = "Avoid parallel perfect consonances on consecutive downbeats."

  private

  def analyzed_harmonic_intervals
    downbeat_harmonic_intervals
  end
end
