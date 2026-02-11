# Module for style guidelines.
module HeadMusic::Style::Guidelines; end

# A counterpoint guideline
class HeadMusic::Style::Guidelines::NoParallelPerfectOnDownbeats < HeadMusic::Style::Annotation
  MESSAGE = "Avoid parallel perfect consonances on consecutive downbeats."

  def marks
    parallel_perfect_downbeat_pairs.map do |pair|
      HeadMusic::Style::Mark.for_all(pair.flat_map(&:notes))
    end
  end

  private

  def parallel_perfect_downbeat_pairs
    downbeat_harmonic_intervals.each_cons(2).select do |first, second|
      first.perfect_consonance?(:two_part_harmony) &&
        second.perfect_consonance?(:two_part_harmony) &&
        same_simple_type?(first, second)
    end
  end

  def same_simple_type?(first, second)
    first.simple_number == second.simple_number
  end
end
