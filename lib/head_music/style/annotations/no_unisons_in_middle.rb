# frozen_string_literal: true

# Module for Annotations.
module HeadMusic::Style::Annotations; end

# A counterpoint guideline
class HeadMusic::Style::Annotations::NoUnisonsInMiddle < HeadMusic::Style::Annotation
  MESSAGE = 'Unisons may only be used in the first and last note.'

  def marks
    unison_pairs.map do |notes|
      HeadMusic::Style::Mark.for_all(notes)
    end.flatten
  end

  private

  def unison_pairs
    middle_unisons.map(&:notes).compact
  end

  def middle_unisons
    middle_intervals.select { |interval| interval.perfect_consonance? && interval.unison? }
  end

  def middle_intervals
    [harmonic_intervals[1..-2]].flatten.compact
  end
end
