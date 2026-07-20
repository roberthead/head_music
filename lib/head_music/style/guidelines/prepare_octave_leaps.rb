# Module for style guidelines.
module HeadMusic::Style::Guidelines; end

# A counterpoint guideline
class HeadMusic::Style::Guidelines::PrepareOctaveLeaps < HeadMusic::Style::Annotation
  MESSAGE = "Enter and exit an octave leap from within."

  def marks
    external_entries_marks + external_exits_marks + octave_ending_marks
  end

  private

  def external_entries_marks
    external_entries.map do |trouble_spot|
      HeadMusic::Style::Mark.for_all(trouble_spot)
    end
  end

  def external_exits_marks
    external_exits.map do |trouble_spot|
      HeadMusic::Style::Mark.for_all(trouble_spot)
    end
  end

  def octave_ending_marks
    return [] unless octave_ending?

    [HeadMusic::Style::Mark.for_all(octave_ending)]
  end

  def external_entries
    external_leaps { |first, second| second.octave? && !second.spans?(first.pitches.first) }
  end

  def external_exits
    external_leaps { |first, second| first.octave? && !first.spans?(second.pitches.last) }
  end

  # Adjacent melodic-interval pairs whose octave leap is approached or left from
  # outside the span, as decided by the given predicate.
  def external_leaps
    melodic_note_pairs.each_cons(2).filter_map do |pair|
      first, second = *pair
      pair.map(&:notes).flatten.uniq if yield(first, second)
    end
  end

  def octave_ending
    octave_ending? ? melodic_note_pairs.last.notes : []
  end

  def octave_ending?
    melodic_note_pairs.last&.octave?
  end
end
