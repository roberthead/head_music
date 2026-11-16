# Module for style guidelines.
module HeadMusic::Style::Guidelines; end

# A counterpoint guideline.
# Dissonant downbeats are permitted only as suspensions: a note held over
# the barline in either voice, or with `restruck_suspensions: true`, struck
# again there. Whether it is prepared and resolved is the suspension rule's
# to judge.
class HeadMusic::Style::Guidelines::ConsonantDownbeats < HeadMusic::Style::Guideline
  include HeadMusic::Style::Guideline::RestruckSuspensions

  def marks
    dissonant_pairs.map do |dissonant_pair|
      HeadMusic::Style::Mark.for_all(dissonant_pair)
    end.flatten
  end

  private

  def dissonant_pairs
    non_suspension_dissonant_intervals.map(&:notes).compact
  end

  def non_suspension_dissonant_intervals
    dissonant_intervals.reject { |interval| tied_suspension?(interval) }
  end

  def dissonant_intervals
    downbeat_harmonic_intervals.select { |interval| interval.dissonance?(:two_part_harmony) }
  end

  def tied_suspension?(interval)
    interval.notes.any? do |note|
      note.position < interval.position || (restruck_suspensions? && restruck_on_stronger_beat?(note))
    end
  end
end
