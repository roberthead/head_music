# Module for style guidelines.
module HeadMusic::Style::Guidelines; end

# Base class for guidelines flagging parallel perfect consonances between
# consecutive harmonic intervals. Subclasses supply the set of harmonic
# intervals to analyze (e.g. downbeats or all syncopated positions).
class HeadMusic::Style::Guidelines::NoParallelPerfect < HeadMusic::Style::Annotation
  def marks
    parallel_perfect_pairs.map do |pair|
      HeadMusic::Style::Mark.for_all(pair.flat_map(&:notes))
    end
  end

  private

  def analyzed_harmonic_intervals
    raise NotImplementedError
  end

  def parallel_perfect_pairs
    analyzed_harmonic_intervals.each_cons(2).select do |first, second|
      first.perfect_consonance?(:two_part_harmony) &&
        second.perfect_consonance?(:two_part_harmony) &&
        same_simple_type?(first, second)
    end
  end

  def same_simple_type?(first, second)
    first.simple_number == second.simple_number
  end
end
