# frozen_string_literal: true

# Module for Annotations.
module HeadMusic::Style::Annotations; end

# A counterpoint guideline
class HeadMusic::Style::Annotations::PrepareOctaveLeaps < HeadMusic::Style::Annotation
  MESSAGE = 'Enter and exit an octave leap from within.'

  def marks
    (external_entries + external_exits + octave_ending).map do |trouble_spot|
      HeadMusic::Style::Mark.for_all(trouble_spot)
    end
  end

  private

  def external_entries
    melodic_intervals.each_cons(2).map do |pair|
      first, second = *pair
      pair.map(&:notes).uniq if second.octave? && !second.spans?(first.first_note.pitch)
    end.compact
  end

  def external_exits
    melodic_intervals.each_cons(2).map do |pair|
      first, second = *pair
      pair.map(&:notes).uniq if first.octave? && !first.spans?(second.second_note.pitch)
    end.compact
  end

  def octave_ending
    octave_ending? ? [melodic_intervals.last.notes] : []
  end

  def octave_ending?
    melodic_intervals.last&.octave?
  end
end
